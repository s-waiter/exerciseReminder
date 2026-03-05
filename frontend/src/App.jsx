import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Home from './pages/Home';

// Admin Pages
import AdminLogin from './pages/Admin/Login';
import AdminDashboard from './pages/Admin/Dashboard';
import AdminLayout from './pages/Admin/Layout';
import AdminWebsiteStats from './pages/Admin/WebsiteStats';
import AdminAppStats from './pages/Admin/AppStats';
import AdminCodes from './pages/Admin/Codes';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        
        {/* Admin Routes */}
        <Route path="/admin/login" element={<AdminLogin />} />
        
        <Route path="/admin" element={<AdminLayout />}>
           <Route index element={<Navigate to="/admin/dashboard" replace />} />
           <Route path="dashboard" element={<AdminDashboard />} />
           <Route path="website-stats" element={<AdminWebsiteStats />} />
           <Route path="app-stats" element={<AdminAppStats />} />
           <Route path="codes" element={<AdminCodes />} />
        </Route>

        {/* Catch all - redirect to home */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
