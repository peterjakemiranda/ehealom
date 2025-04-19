<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Laravel\Firebase\Facades\Firebase;

class NotificationService
{
    /**
     * Send a push notification to a single device
     *
     * @param string $token FCM device token
     * @param string $title Notification title
     * @param string $body Notification body
     * @param array $data Additional data to send with the notification
     * @return bool
     */
    public function sendNotification(string $token, string $title, string $body, array $data = []): bool
    {
        try {
            $messaging = Firebase::messaging();
            
            $notification = Notification::create($title, $body);
            
            $message = CloudMessage::withTarget('token', $token)
                ->withNotification($notification);
                
            if (!empty($data)) {
                $message = $message->withData($data);
            }
            
            $messaging->send($message);
            
            return true;
        } catch (\Exception $e) {
            Log::error('Failed to send push notification: ' . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Send push notifications to multiple devices
     *
     * @param array $tokens Array of FCM device tokens
     * @param string $title Notification title
     * @param string $body Notification body
     * @param array $data Additional data to send with the notification
     * @return bool
     */
    public function sendMultipleNotifications(array $tokens, string $title, string $body, array $data = []): bool
    {
        try {
            $messaging = Firebase::messaging();
            
            $notification = Notification::create($title, $body);
            
            $messages = [];
            foreach ($tokens as $token) {
                if (!empty($token)) {
                    $message = CloudMessage::withTarget('token', $token)
                        ->withNotification($notification);
                        
                    if (!empty($data)) {
                        $message = $message->withData($data);
                    }
                    
                    $messages[] = $message;
                }
            }
            
            if (!empty($messages)) {
                $messaging->sendAll($messages);
            }
            
            return true;
        } catch (\Exception $e) {
            Log::error('Failed to send multiple push notifications: ' . $e->getMessage());
            return false;
        }
    }
} 