<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Company;
use Illuminate\Http\Request;
use App\Http\Resources\CompanyResource;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CompanyController extends Controller
{
    public function getUserCompanies()
    {
        $companies = auth()->user()->companies()->withPivot('is_default')->get();
        return CompanyResource::collection($companies);
    }

    public function index()
    {
        $companies = auth()->user()->companies()->withPivot('is_default')->paginate();
        return CompanyResource::collection($companies);
    }

    public function store(Request $request)
    {
        try {
            DB::beginTransaction();

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'logo' => 'nullable|string'
            ]);

            $company = Company::create([
                'name' => $validated['name'],
                'logo' => $validated['logo'] ?? null,
            ]);

            // Set as default if this is user's first company
            $isDefault = !auth()->user()->companies()->exists();
            $company->users()->attach(auth()->id(), ['is_default' => $isDefault]);

            DB::commit();
            return new CompanyResource($company->load('users'));

        } catch (ValidationException $e) {
            DB::rollBack();
            throw $e;
        } catch (\Exception $e) {
            info($e);
            DB::rollBack();
            return response()->json(['message' => 'Failed to create company'], 500);
        }
    }

    public function show(string $uuid)
    {
        $company = Company::where('uuid', $uuid)->firstOrFail();
        $this->authorize('view', $company);
        return new CompanyResource($company->load('users'));
    }

    public function update(Request $request, string $uuid)
    {
        try {
            $company = Company::where('uuid', $uuid)->firstOrFail();
            $this->authorize('update', $company);

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'logo' => 'nullable|string'
            ]);

            $company->update([
                'name' => $validated['name'],
                'logo' => $validated['logo'] ?? $company->logo
            ]);

            return new CompanyResource($company->fresh());

        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to update company'], 500);
        }
    }

    public function setDefault(string $uuid)
    {
        try {
            DB::beginTransaction();
            $company = Company::where('uuid', $uuid)->firstOrFail();

            $user = auth()->user();
            
            // Ensure user belongs to this company
            if (!$user->companies->contains($company->id)) {
                throw new \Exception('Unauthorized access to company');
            }

            // Remove default from all user's companies
            $user->companies()->updateExistingPivot(
                $user->companies->pluck('id'),
                ['is_default' => false]
            );
            
            // Set new default
            $user->companies()->updateExistingPivot(
                $company->id,
                ['is_default' => true]
            );

            DB::commit();
            return new CompanyResource($company->fresh());

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to set default company'], 500);
        }
    }

    public function destroy(string $uuid)
    {
        try {
            $company = Company::where('uuid', $uuid)->firstOrFail();
            $this->authorize('delete', $company);
            
            if ($company->users()->count() > 1) {
                return response()->json([
                    'message' => 'Cannot delete company with multiple users'
                ], 403);
            }

            // Check if this is the user's last company
            if (auth()->user()->companies()->count() === 1) {
                return response()->json([
                    'message' => 'Cannot delete your only company'
                ], 403);
            }

            $company->delete();
            return response()->json(null, 204);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to delete company'], 500);
        }
    }
}
