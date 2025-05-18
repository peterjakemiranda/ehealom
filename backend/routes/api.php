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
use App\Http\Controllers\Api\EmergencyController;
use App\Http\Controllers\Api\EmergencyHotlineController;
use App\Http\Controllers\Api\FirstAidController;
use App\Http\Controllers\Api\AlertController;
use App\Http\Controllers\Api\ResourceController;
use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\CounselorScheduleController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\NotificationController;

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

// Public settings routes
Route::get('/settings/terms', [SettingController::class, 'termsAndConditions']);

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // FCM Notification Token updates
    Route::post('/notification/token', [NotificationController::class, 'updateToken']);

    Route::apiResource('categories', CategoryController::class);
    
    Route::apiResource('roles', RoleController::class);
    Route::get('users/search', [UserController::class, 'searchStudents']);

    Route::apiResource('users', UserController::class);

    Route::patch('users/{user}/toggle-status', [UserController::class, 'toggleStatus']);

    Route::get('permissions', [RoleController::class, 'permissions']);
    Route::post('roles/assign', [RoleController::class, 'assignRole']);
    
    // Settings routes
    Route::get('/settings', [SettingController::class, 'index']);
    Route::post('/settings', [SettingController::class, 'update']);
    
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);

    Route::apiResource('alerts', AlertController::class);

    // Resource routes with permissions
    Route::prefix('resources')->group(function () {
        Route::get('/', [ResourceController::class, 'index'])
            ->middleware('permission:view resources');
        
        Route::post('/', [ResourceController::class, 'store'])
            ->middleware('permission:manage resources');
        
        Route::get('/{resource}', [ResourceController::class, 'show'])
            ->middleware('permission:view resources');
        
        Route::put('/{resource}', [ResourceController::class, 'update'])
            ->middleware('permission:manage resources');
        
        Route::delete('/{resource}', [ResourceController::class, 'destroy'])
            ->middleware('permission:manage resources');
    });

    // Appointment routes
    Route::get('/appointments/counts', [AppointmentController::class, 'getCounts']);
    Route::get('/appointments/available-slots', [AppointmentController::class, 'getAvailableSlots']);
    Route::get('/appointments/departments', [AppointmentController::class, 'getDepartments']);
    Route::apiResource('appointments', AppointmentController::class)->parameters([
        'appointments' => 'appointment:uuid'
    ]);
    
    // Counselor Schedule routes
    Route::prefix('counselor')->middleware('role:counselor')->group(function () {
        Route::get('schedule', [CounselorScheduleController::class, 'getSchedule']);
        Route::post('schedule', [CounselorScheduleController::class, 'updateSchedule']);
        Route::post('excluded-dates', [CounselorScheduleController::class, 'updateExcludedDates']);
        Route::delete('excluded-dates/{id}', [CounselorScheduleController::class, 'deleteExcludedDate']);
    });

    // Chat routes
    Route::get('/chat/messages', [ChatController::class, 'index']);
    Route::post('/chat/messages', [ChatController::class, 'store']);

    // Reporting Routes
    Route::prefix('reports')->middleware('permission:view reports')->group(function () {
        Route::get('appointments-by-category-daily', [ReportController::class, 'appointmentsByCategoryDaily']);
        Route::get('appointments-by-age-daily', [ReportController::class, 'appointmentsByAgeDaily']);
        Route::get('appointments-by-department-daily', [ReportController::class, 'appointmentsByDepartmentDaily']);
    });
});