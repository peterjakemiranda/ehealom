<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Alert;
use App\Http\Resources\AlertResource;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AlertController extends Controller
{
    public function index(Request $request)
    {
        $query = Alert::query()->with('reporter');
        
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('department')) {
            $query->where('department', $request->department);
        }

        $alerts = $query->orderByDesc('created_at')->paginate(10);

        return AlertResource::collection($alerts);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'type' => 'required|in:admin,emergency',
            'notification_type' => 'required|in:all,push,sms',
            'department' => 'nullable|string',
        ]);

        $alert = Alert::create([
            ...$validated,
            'reported_by' => auth()->id(),
            'sent_at' => Carbon::now(),
        ]);

        // TODO: Send notifications based on notification_type
        // You'll need to implement the actual notification sending logic

        return new AlertResource($alert);
    }

    public function show(Alert $alert)
    {
        return new AlertResource($alert->load('reporter'));
    }

    public function update(Request $request, Alert $alert)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'notification_type' => 'required|in:all,push,sms',
            'department' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $alert->update($validated);

        return new AlertResource($alert);
    }

    public function destroy(Alert $alert)
    {
        $alert->delete();
        return response()->noContent();
    }
} 