<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SettingsTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Insert default settings
        DB::table('settings')->updateOrInsert([
            'key' => 'terms_and_conditions',
        ], [
            'value' => '<h1>E-Healom Terms and Conditions</h1>

<h2>Introduction</h2>
<p>Welcome to E-Healom, a campus mental health support platform. By accessing or using our services, you agree to be bound by these Terms and Conditions. Please read them carefully before using our platform.</p>

<h2>1. Acceptance of Terms</h2>
<p>By accessing or using E-Healom, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, please do not use our services.</p>

<h2>2. Description of Services</h2>
<p>E-Healom provides a platform for:</p>
<ul>
    <li>Scheduling confidential counseling sessions with campus counselors</li>
    <li>Accessing mental health resources and educational materials</li>
    <li>Managing appointments and communications with counselors</li>
    <li>Receiving support in a safe, confidential environment</li>
</ul>

<h2>3. User Registration</h2>
<p>To use certain features of E-Healom, you must register for an account. You agree to:</p>
<ul>
    <li>Provide accurate and complete information during registration</li>
    <li>Maintain the security of your account credentials</li>
    <li>Promptly update your account information as needed</li>
    <li>Accept responsibility for all activities that occur under your account</li>
</ul>

<h2>4. User Conduct</h2>
<p>You agree to use E-Healom only for lawful purposes and in accordance with these Terms. You agree not to:</p>
<ul>
    <li>Use the service in any way that violates applicable laws or regulations</li>
    <li>Impersonate or attempt to impersonate another user or person</li>
    <li>Engage in any conduct that restricts or inhibits anyone\'s use of the service</li>
    <li>Attempt to gain unauthorized access to any portion of the service</li>
    <li>Use the service to harass, abuse, or harm others</li>
</ul>

<h2>5. Confidentiality</h2>
<p>E-Healom is designed to provide confidential mental health support. However, please be aware that:</p>
<ul>
    <li>Counselors may be required to report certain situations, such as imminent risk of harm</li>
    <li>Electronic communications may not be completely secure</li>
    <li>We cannot guarantee absolute confidentiality of information transmitted through our platform</li>
</ul>

<h2>6. Intellectual Property</h2>
<p>All content, features, and functionality of E-Healom are owned by us and are protected by international copyright, trademark, and other intellectual property laws.</p>

<h2>7. Limitation of Liability</h2>
<p>E-Healom is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use of our services.</p>

<h2>8. Changes to Terms</h2>
<p>We reserve the right to modify these Terms at any time. We will notify users of any material changes by posting the new Terms on this page.</p>

<h2>9. Contact Information</h2>
<p>If you have any questions about these Terms, please contact us at <a href="mailto:support@ehealom.com">support@ehealom.com</a>.</p>

<p><em>Last Updated: ' . now()->format('F d, Y') . '</em></p>',
            'type' => 'html',
            'description' => 'Terms and Conditions for the E-Healom mental health support platform',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
