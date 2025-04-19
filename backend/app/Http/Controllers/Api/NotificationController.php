<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    /**
     * Update the user's FCM token
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function updateToken(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = Auth::user();
        $user->fcm_token = $validated['fcm_token'];
        $user->save();

        return response()->json([
            'message' => 'FCM token updated successfully'
        ]);
    }
}
