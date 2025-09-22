"""
Pricing Engine for evaluating billing rules and calculating rates.
This is the core business logic that makes the platform flexible and powerful.
"""

from datetime import datetime, date, time as dt_time
from decimal import Decimal
from typing import Dict, Any, List, Optional, Union
from uuid import UUID
import uuid

from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.db.models.billing_rules import BillingRule, ScopeEnum
from app.db.models.tasks import Task
from app.db.models.users import User
from app.db.models.contractor_profiles import ContractorProfile
from app.db.models.projects import Project
from app.db.models.clients import Client


class PricingEngine:
    """
    Core pricing engine that evaluates billing rules in priority order.

    Evaluation order: ORG → CLIENT → PROJECT → TASK → USER
    Within each scope, rules are evaluated by priority (lower number = higher priority).
    First rule that sets a field "wins" unless override=true.
    """

    def __init__(self):
        self.default_rate = Decimal('100.00')
        self.default_min_increment = 15  # minutes
        self.default_overtime_multiplier = Decimal('1.5')

    def evaluate_pricing(self, context: Dict[str, Any], db: Session) -> Dict[str, Any]:
        """
        Evaluate billing rules for a given context and return pricing information.

        Args:
            context: Dict containing contextual information like:
                - org_id: Organization ID (required)
                - client_id: Client ID (optional)
                - project_id: Project ID (optional)
                - task_id: Task ID (optional)
                - contractor_user_id: User ID (optional)
                - task_category: Task category (optional)
                - start_at: Start datetime (optional)
                - duration_minutes: Duration in minutes (optional)
                - day_of_week: Day of week (optional, will be calculated from start_at)
                - time_of_day: Time of day (optional, will be calculated from start_at)
                - location: Location data (optional)
                - source: Entry source (optional)
            db: Database session

        Returns:
            Dict with calculated pricing including:
                - rate: Effective hourly rate
                - min_increment_min: Minimum time increment in minutes
                - overtime_multiplier: Overtime rate multiplier
                - materials_markup_pct: Materials markup percentage
                - applied_rules: List of rules that were applied
        """

        # Initialize result with defaults
        result = {
            "rate": float(self.default_rate),
            "min_increment_min": self.default_min_increment,
            "overtime_multiplier": float(self.default_overtime_multiplier),
            "materials_markup_pct": 0.0,
            "applied_rules": []
        }

        # Enhance context with calculated fields
        enhanced_context = self._enhance_context(context, db)

        # Get all applicable rules for this organization
        rules = self._get_applicable_rules(enhanced_context, db)

        # Group rules by scope for ordered evaluation
        rules_by_scope = self._group_rules_by_scope(rules)

        # Evaluate rules in priority order: ORG → CLIENT → PROJECT → TASK → USER
        scope_order = [ScopeEnum.ORG, ScopeEnum.CLIENT, ScopeEnum.PROJECT, ScopeEnum.TASK, ScopeEnum.USER]

        for scope in scope_order:
            if scope in rules_by_scope:
                scope_rules = sorted(rules_by_scope[scope], key=lambda r: r.priority)
                for rule in scope_rules:
                    if self._rule_matches_context(rule, enhanced_context):
                        self._apply_rule_effects(rule, result, enhanced_context)

        return result

    def get_base_rate(
        self,
        task_id: Optional[UUID] = None,
        user_id: Optional[UUID] = None,
        db: Session = None
    ) -> Decimal:
        """
        Get base rate without rule evaluation.
        Priority: Task rate > User contractor rate > Default rate
        """
        if task_id and db:
            task = db.query(Task).filter(Task.id == task_id).first()
            if task and task.default_rate and float(task.default_rate) > 0:
                return Decimal(str(task.default_rate))

        if user_id and db:
            contractor_profile = db.query(ContractorProfile).filter(
                ContractorProfile.user_id == user_id,
                ContractorProfile.active == True
            ).first()
            if contractor_profile and contractor_profile.default_rate and float(contractor_profile.default_rate) > 0:
                return Decimal(str(contractor_profile.default_rate))

        return self.default_rate

    def _enhance_context(self, context: Dict[str, Any], db: Session) -> Dict[str, Any]:
        """Enhance context with calculated fields and related data."""
        enhanced = context.copy()

        # Parse datetime if provided
        if "start_at" in context and isinstance(context["start_at"], str):
            enhanced["start_at"] = datetime.fromisoformat(context["start_at"].replace('Z', '+00:00'))

        # Calculate day of week and time of day if start_at is provided
        if "start_at" in enhanced and isinstance(enhanced["start_at"], datetime):
            start_dt = enhanced["start_at"]
            enhanced["day_of_week"] = start_dt.strftime("%a").upper()  # MON, TUE, etc.
            enhanced["time_of_day"] = start_dt.strftime("%H:%M")

        # Get task category if task_id provided but category not specified
        if "task_id" in context and "task_category" not in context and db:
            task = db.query(Task).filter(Task.id == context["task_id"]).first()
            if task:
                enhanced["task_category"] = task.category

        # Get project info if needed
        if "project_id" in context and db:
            project = db.query(Project).filter(Project.id == context["project_id"]).first()
            if project:
                enhanced["client_id"] = str(project.client_id)

        # Convert UUIDs to strings for consistent comparison
        for key in ["org_id", "client_id", "project_id", "task_id", "contractor_user_id"]:
            if key in enhanced and enhanced[key]:
                enhanced[key] = str(enhanced[key])

        return enhanced

    def _get_applicable_rules(self, context: Dict[str, Any], db: Session) -> List[BillingRule]:
        """Get all potentially applicable rules for the organization."""
        org_id = context.get("org_id")
        if not org_id:
            return []

        # Get all active rules for this organization
        rules = db.query(BillingRule).filter(
            and_(
                BillingRule.org_id == org_id,
                BillingRule.active == True
            )
        ).all()

        # Filter rules by scope applicability
        applicable_rules = []
        for rule in rules:
            if self._is_rule_applicable(rule, context):
                applicable_rules.append(rule)

        return applicable_rules

    def _is_rule_applicable(self, rule: BillingRule, context: Dict[str, Any]) -> bool:
        """Check if a rule is applicable based on its scope."""
        if rule.scope == ScopeEnum.ORG:
            return True  # ORG rules always apply

        elif rule.scope == ScopeEnum.CLIENT:
            if rule.scope_id:
                return context.get("client_id") == str(rule.scope_id)
            return "client_id" in context

        elif rule.scope == ScopeEnum.PROJECT:
            if rule.scope_id:
                return context.get("project_id") == str(rule.scope_id)
            return "project_id" in context

        elif rule.scope == ScopeEnum.TASK:
            if rule.scope_id:
                return context.get("task_id") == str(rule.scope_id)
            return "task_id" in context

        elif rule.scope == ScopeEnum.USER:
            if rule.scope_id:
                return context.get("contractor_user_id") == str(rule.scope_id)
            return "contractor_user_id" in context

        return False

    def _group_rules_by_scope(self, rules: List[BillingRule]) -> Dict[ScopeEnum, List[BillingRule]]:
        """Group rules by their scope."""
        grouped = {}
        for rule in rules:
            if rule.scope not in grouped:
                grouped[rule.scope] = []
            grouped[rule.scope].append(rule)
        return grouped

    def _rule_matches_context(self, rule: BillingRule, context: Dict[str, Any]) -> bool:
        """Check if a rule's conditions match the current context."""
        rule_data = rule.rule

        # Check if rule is active based on date range
        if not self._is_rule_date_active(rule_data, context):
            return False

        # Check conditions
        conditions = rule_data.get("conditions", {})
        if not conditions:
            return True  # No conditions means always matches

        for condition_key, condition_value in conditions.items():
            if not self._condition_matches(condition_key, condition_value, context):
                return False

        return True

    def _is_rule_date_active(self, rule_data: Dict[str, Any], context: Dict[str, Any]) -> bool:
        """Check if rule is active based on date range."""
        date_range = rule_data.get("active_date_range")
        if not date_range:
            return True

        # Get current date or date from context
        current_date = date.today()
        if "start_at" in context and isinstance(context["start_at"], datetime):
            current_date = context["start_at"].date()

        # Check from date
        if "from" in date_range and date_range["from"]:
            from_date = datetime.strptime(date_range["from"], "%Y-%m-%d").date()
            if current_date < from_date:
                return False

        # Check to date
        if "to" in date_range and date_range["to"]:
            to_date = datetime.strptime(date_range["to"], "%Y-%m-%d").date()
            if current_date > to_date:
                return False

        return True

    def _condition_matches(self, condition_key: str, condition_value: Any, context: Dict[str, Any]) -> bool:
        """Check if a specific condition matches the context."""

        if condition_key == "client_id":
            return context.get("client_id") == str(condition_value)

        elif condition_key == "project_id":
            return context.get("project_id") == str(condition_value)

        elif condition_key == "task_id":
            return context.get("task_id") == str(condition_value)

        elif condition_key == "task_category":
            return context.get("task_category") == condition_value

        elif condition_key == "contractor_user_id":
            return context.get("contractor_user_id") == str(condition_value)

        elif condition_key == "day_of_week":
            if isinstance(condition_value, list):
                return context.get("day_of_week") in condition_value
            return context.get("day_of_week") == condition_value

        elif condition_key == "time_of_day":
            return self._time_in_range(context.get("time_of_day"), condition_value)

        elif condition_key == "source":
            return context.get("source") == condition_value

        elif condition_key == "location":
            return self._location_matches(context.get("location"), condition_value)

        # Add more condition types as needed
        return True

    def _time_in_range(self, current_time: Optional[str], time_range: Dict[str, str]) -> bool:
        """Check if current time falls within the specified range."""
        if not current_time or not isinstance(time_range, dict):
            return True

        try:
            current = datetime.strptime(current_time, "%H:%M").time()

            if "from" in time_range:
                from_time = datetime.strptime(time_range["from"], "%H:%M").time()
                if "to" in time_range:
                    to_time = datetime.strptime(time_range["to"], "%H:%M").time()

                    # Handle overnight ranges (e.g., 18:00 to 06:00)
                    if from_time > to_time:
                        return current >= from_time or current <= to_time
                    else:
                        return from_time <= current <= to_time
                else:
                    return current >= from_time

            return True
        except ValueError:
            return True

    def _location_matches(self, current_location: Optional[Dict], location_condition: Dict) -> bool:
        """Check if current location matches the condition (basic implementation)."""
        # This would implement geo-fencing logic
        # For now, just return True as a placeholder
        return True

    def _apply_rule_effects(self, rule: BillingRule, result: Dict[str, Any], context: Dict[str, Any]) -> None:
        """Apply a rule's effects to the result."""
        rule_data = rule.rule
        effects = rule_data.get("effects", {})

        if not effects:
            return

        # Track applied rule
        applied_rule = {
            "id": str(rule.id),
            "name": rule_data.get("name", "Unnamed Rule"),
            "scope": rule.scope.value,
            "priority": rule.priority,
            "effects_applied": []
        }

        for effect_key, effect_value in effects.items():
            if self._should_apply_effect(effect_key, effect_value, result, rule_data):
                old_value = result.get(effect_key)
                new_value = self._apply_effect(effect_key, effect_value, result, context)

                if new_value is not None:
                    result[effect_key] = new_value
                    applied_rule["effects_applied"].append({
                        "field": effect_key,
                        "old_value": old_value,
                        "new_value": new_value,
                        "operation": effect_value.get("op", "set") if isinstance(effect_value, dict) else "set"
                    })

        # Only add rule to applied_rules if it actually applied some effects
        if applied_rule["effects_applied"]:
            result["applied_rules"].append(applied_rule)

    def _should_apply_effect(self, effect_key: str, effect_value: Any, result: Dict[str, Any], rule_data: Dict[str, Any]) -> bool:
        """Check if an effect should be applied based on override rules."""
        # If override is True, always apply
        if rule_data.get("override", False):
            return True

        # For multiply and add operations, always apply (they don't "set" values)
        if isinstance(effect_value, dict) and effect_value.get("op") in ["multiply", "add"]:
            return True

        # If the field hasn't been set yet (still at default), apply
        if effect_key not in result or result[effect_key] is None:
            return True

        # Check if this is the first time the field is being modified from its default
        # This allows the first rule to modify defaults without being considered "already set"
        default_values = {
            "rate": float(self.default_rate),
            "min_increment_min": self.default_min_increment,
            "overtime_multiplier": float(self.default_overtime_multiplier),
            "materials_markup_pct": 0.0
        }

        if effect_key in default_values and result[effect_key] == default_values[effect_key]:
            return True

        # If the field has been set by a previous rule, don't override unless explicitly allowed
        return False

    def _apply_effect(self, effect_key: str, effect_value: Any, result: Dict[str, Any], context: Dict[str, Any]) -> Any:
        """Apply a specific effect and return the new value."""

        # Handle simple value assignment
        if not isinstance(effect_value, dict) or "op" not in effect_value:
            return self._convert_effect_value(effect_value)

        operation = effect_value["op"]
        value = effect_value.get("value")

        current_value = result.get(effect_key, 0)

        if operation == "set":
            return self._convert_effect_value(value)

        elif operation == "multiply":
            return float(current_value) * float(value)

        elif operation == "add":
            return float(current_value) + float(value)

        else:
            # Unknown operation, just set the value
            return self._convert_effect_value(value)

    def _convert_effect_value(self, value: Any) -> Any:
        """Convert effect value to appropriate type."""
        if isinstance(value, (int, float)):
            return float(value)
        elif isinstance(value, str):
            try:
                return float(value)
            except ValueError:
                return value
        return value


# Global pricing engine instance
pricing_engine = PricingEngine()