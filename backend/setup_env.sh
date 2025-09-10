#!/bin/bash
echo "Setting up Python virtual environment for Contractor Billing Backend..."

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install the package in development mode
pip install -e .

echo ""
echo "Virtual environment setup complete!"
echo ""
echo "To activate the environment, run: source venv/bin/activate"
echo "To deactivate, run: deactivate"
echo ""
echo "To run the FastAPI server:"
echo "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"