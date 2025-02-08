<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Resource;
use Illuminate\Http\Request;
use App\Http\Resources\ResourceResource;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class ResourceController extends Controller
{
    public function index(Request $request)
    {
        $query = Resource::with('categories')
            ->when($request->has('category'), function ($query) use ($request) {
                $query->whereHas('categories', function ($q) use ($request) {
                    $q->where('uuid', $request->category);
                });
            })
            ->when($request->has('search'), function ($query) use ($request) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('content', 'like', "%{$search}%");
                });
            })
            ->orderBy('created_at', 'desc');

        $perPage = $request->input('per_page', 10);
        $resources = $query->paginate($perPage);

        return ResourceResource::collection($resources);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_published' => 'required|boolean',
            'categories' => 'required|string' // Expecting comma-separated string
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $imageUrl = $request->file('image')->store('resource-images', 'public');
        }

        try {
            $data = [
                'title' => $validated['title'],
                'content' => $validated['content'],
                'image_url' => $imageUrl,
                'is_published' => (bool) $validated['is_published'],
                'created_by' => $request->user()->id
            ];
            $resource = Resource::create($data);

            // Convert comma-separated string to array of IDs
            if (!empty($validated['categories'])) {
                $categoryIds = array_map('intval', explode(',', $validated['categories']));
                $resource->categories()->attach($categoryIds);
            }

            return new ResourceResource($resource->load(['creator', 'categories']));
        } catch(\Exception $e) {
            if ($imageUrl) {
                Storage::disk('public')->delete($imageUrl);
            }
            throw $e;
        }
    }

    public function show(Resource $resource)
    {
        // Check if the resource is published or if user has permission to view unpublished
        if (!$resource->is_published && !auth()->user()->can('manage resources')) {
            return response()->json(['message' => 'Resource not found'], 404);
        }

        return new ResourceResource($resource);
    }

    public function update(Request $request, Resource $resource)
    {
        if (!request()->user()->tokenCan('admin')) {
            abort(403, 'Unauthorized to update resources');
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'image' => 'nullable',
            'is_published' => 'required|boolean',
            'categories' => 'required|string'
        ]);

        if ($request->hasFile('image')) {
            if ($request->file('image')->isValid()) {
                if ($resource->image_url) {
                    Storage::disk('public')->delete($resource->image_url);
                }
                $validated['image_url'] = $request->file('image')->store('resource-images', 'public');
            }
        }

        $resource->update($validated);
        
        // Convert comma-separated string to array of IDs
        if (isset($validated['categories'])) {
            $categoryIds = array_map('intval', explode(',', $validated['categories']));
            $resource->categories()->sync($categoryIds);
        }

        return new ResourceResource($resource->fresh()->load(['creator', 'categories']));
    }

    public function destroy(Resource $resource)
    {
        if (!request()->user()->tokenCan('admin')) {
            abort(403, 'Unauthorized to delete resources');
        }

        if ($resource->image_url) {
            Storage::disk('public')->delete($resource->image_url);
        }
        
        $resource->delete();
        return response()->noContent();
    }
} 