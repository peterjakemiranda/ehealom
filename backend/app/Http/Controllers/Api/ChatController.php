<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use Illuminate\Http\Request;
use App\Events\NewChatMessage;
use Illuminate\Support\Facades\Log;

class ChatController extends Controller
{
    public function index()
    {
        $messages = ChatMessage::with('user:id,name,username')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($messages);
    }

    public function store(Request $request)
    {
        try {
            Log::info('Attempting to store chat message', [
                'user_id' => $request->user()->id,
                'message' => $request->message
            ]);

            $validated = $request->validate([
                'message' => 'required|string|max:1000',
            ]);

            $message = ChatMessage::create([
                'user_id' => $request->user()->id,
                'message' => $validated['message'],
            ]);

            Log::info('Message stored successfully', ['message_id' => $message->id]);

            $message->load('user:id,name,username');
            return response()->json($message);
            
        } catch (\Exception $e) {
            Log::error('Failed to store chat message', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'message' => 'Failed to store message',
                'error' => $e->getMessage()
            ], 500);
        }
    }
} 