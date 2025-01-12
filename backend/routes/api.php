<?php

use App\Http\Controllers\Api\CustomerController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\LoanController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\NotificationTemplateController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\RoleController;
use App\Http\Controllers\Api\SyncController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\CompanyController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::apiResource('customers', CustomerController::class);
    Route::apiResource('categories', CategoryController::class);
    
    Route::apiResource('users', UserController::class);
    Route::patch('users/{user}/toggle-status', [UserController::class, 'toggleStatus']);

    Route::apiResource('roles', RoleController::class);
    Route::get('permissions', [RoleController::class, 'permissions']);
    Route::post('roles/assign', [RoleController::class, 'assignRole']);
    
    Route::get('/sync', [SyncController::class, 'sync']);
    
    // Company routes
    Route::get('/user/companies', [CompanyController::class, 'getUserCompanies']);
    Route::get('/companies/{uuid}', [CompanyController::class, 'show']);
    Route::post('/companies', [CompanyController::class, 'store']);
    Route::put('/companies/{uuid}', [CompanyController::class, 'update']);
    Route::delete('/companies/{uuid}', [CompanyController::class, 'destroy']);
    Route::patch('/companies/{uuid}/set-default', [CompanyController::class, 'setDefault']);
    
    // Settings routes
    Route::get('/settings', [SettingController::class, 'index']);
    Route::post('/settings', [SettingController::class, 'update']);
});