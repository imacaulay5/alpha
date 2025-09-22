'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { authAPI } from '@/lib/api';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await authAPI.login(email, password);

      // Store the token and user info
      localStorage.setItem('auth_token', response.access_token);
      localStorage.setItem('user_info', JSON.stringify(response.user));

      // Redirect to dashboard
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Login failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoLogin = (userType: 'admin' | 'manager' | 'contractor') => {
    const demoCredentials = {
      admin: { email: 'admin@demo.com', password: 'admin123' },
      manager: { email: 'manager@demo.com', password: 'manager123' },
      contractor: { email: 'contractor@demo.com', password: 'contractor123' },
    };
    
    const creds = demoCredentials[userType];
    setEmail(creds.email);
    setPassword(creds.password);
  };

  return (
    <div className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-indigo-600 via-purple-600 to-blue-700 relative overflow-hidden">
        <div className="absolute inset-0 bg-black opacity-20"></div>
        <div className="relative z-10 flex flex-col justify-center px-12 text-white">
          <div className="max-w-md">
            <h1 className="text-5xl font-bold mb-6">Alpha</h1>
            <p className="text-xl mb-8 text-indigo-100">
              The modern contractor billing platform built for efficiency and growth.
            </p>
            <div className="space-y-4 text-indigo-100">
              <div className="flex items-center">
                <div className="w-2 h-2 bg-indigo-300 rounded-full mr-3"></div>
                <span>Flexible billing rules & rates</span>
              </div>
              <div className="flex items-center">
                <div className="w-2 h-2 bg-indigo-300 rounded-full mr-3"></div>
                <span>Mobile-first time tracking</span>
              </div>
              <div className="flex items-center">
                <div className="w-2 h-2 bg-indigo-300 rounded-full mr-3"></div>
                <span>Powerful subcontractor management</span>
              </div>
            </div>
          </div>
        </div>
        {/* Background Pattern */}
        <div className="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full transform translate-x-16 -translate-y-16"></div>
        <div className="absolute bottom-0 left-0 w-24 h-24 bg-white opacity-10 rounded-full transform -translate-x-12 translate-y-12"></div>
      </div>

      {/* Right side - Login Form */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-6 lg:px-20 xl:px-24 bg-white">
        <div className="max-w-md w-full space-y-8">
          <div className="text-center lg:text-left">
            <div className="lg:hidden mb-8">
              <h1 className="text-4xl font-bold text-gray-900 mb-2">Alpha</h1>
            </div>
            <h2 className="text-3xl font-bold text-gray-900 mb-2">
              Welcome back
            </h2>
            <p className="text-gray-600">
              Sign in to your account to continue
            </p>
          </div>
          
          {/* Quick Demo Access */}
          <div className="bg-gray-50 rounded-xl p-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">Quick Demo Access</h3>
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={() => handleDemoLogin('admin')}
                className="px-3 py-2 text-xs font-medium text-indigo-700 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition-colors duration-200"
              >
                Admin
              </button>
              <button
                onClick={() => handleDemoLogin('manager')}
                className="px-3 py-2 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors duration-200"
              >
                Manager
              </button>
              <button
                onClick={() => handleDemoLogin('contractor')}
                className="px-3 py-2 text-xs font-medium text-blue-700 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors duration-200"
              >
                Contractor
              </button>
            </div>
          </div>

          <form className="space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}
            
            <div className="space-y-4">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                  Email address
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors duration-200 text-gray-900 placeholder-gray-500 bg-white"
                  placeholder="Enter your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
              
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                  Password
                </label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors duration-200 text-gray-900 placeholder-gray-500 bg-white"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-semibold py-3 px-4 rounded-lg transition-all duration-200 transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Signing in...
                </div>
              ) : (
                'Sign in to Alpha'
              )}
            </button>
          </form>

          <p className="text-center text-sm text-gray-500">
            Need help? Contact support at{' '}
            <a href="mailto:support@alpha.com" className="text-indigo-600 hover:text-indigo-500">
              support@alpha.com
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}