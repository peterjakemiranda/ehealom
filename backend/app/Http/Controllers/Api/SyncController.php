<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SyncController extends Controller
{
    private const CHUNK_SIZE = 1000;
    private const CACHE_TTL = 300; // 5 minutes

    public function sync(Request $request)
    {
        $since = Carbon::parse($request->input('since'));
        $table = $request->input('table', 'all');
        $lastId = (int) $request->input('last_id', 0);
        $chunkSize = (int) $request->input('chunk_size', self::CHUNK_SIZE);

        try {
            if ($table === 'all') {
                return $this->handleFullSync($since);
            }

            return $this->handleTableSync($table, $since, $lastId, $chunkSize);
        } catch (\Exception $e) {
            Log::error('Sync error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    private function handleFullSync($since)
    {
        $counts = $this->getUpdateCounts($since);
        $total = array_sum($counts);

        if ($total > 1000) {
            return response()->json([
                'meta' => [
                    'recommendation' => 'Use individual table endpoints',
                    'counts' => $counts,
                    'total' => $total,
                ],
            ]);
        }

        // Use cache to improve performance for frequently accessed data
        $cacheKey = 'full_sync_'.$since->timestamp;

        return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($since) {
            return response()->json([
                'data' => [
                    'customers' => $this->getCustomersUpdates($since)['items'],
                    'loans' => $this->getLoansUpdates($since)['items'],
                    'items' => $this->getItemsUpdates($since)['items'],
                    'categories' => $this->getCategoriesUpdates($since)['items'],
                ],
                'meta' => [
                    'last_sync' => now()->toISOString(),
                    'counts' => $this->getUpdateCounts($since),
                ],
            ]);
        });
    }

    private function handleTableSync($table, $since, $lastId, $chunkSize)
    {
        $method = 'get'.ucfirst(strtolower($table)).'Updates';

        if (method_exists($this, $method)) {
            $data = $this->$method($since, $lastId, $chunkSize);

            return response()->json([
                'data' => $data['items'],
                'meta' => [
                    'has_more' => $data['has_more'],
                    'next_chunk_id' => $data['next_id'],
                    'last_sync' => now()->toISOString(),
                ],
            ]);
        }

        return response()->json([
            'error' => 'Invalid table',
            'message' => "Table '{$table}' is not supported for syncing",
            'supported_tables' => ['customers', 'loans', 'items'],
        ], 400);
    }

    private function getCustomersUpdates($since, $lastId = 0, $limit = self::CHUNK_SIZE)
    {
        $query = DB::table('customers')
            ->select([
                'id', 'uuid', 'first_name', 'last_name', 'address',
                'id_type', 'id_number', 'phone_number', 'email',
                'preferred_communication_channel', 'remarks',
                'created_at', 'updated_at',
            ])
            ->where('id', '>', $lastId)
            ->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('created_at', '>', $since);
            })
            ->orderBy('id')
            ->limit($limit + 1);

        $customers = $query->get();
        $hasMore = $customers->count() > $limit;

        if ($hasMore) {
            $customers = $customers->take($limit);
        }

        return [
            'items' => $customers,
            'has_more' => $hasMore,
            'next_id' => $hasMore ? $customers->last()->id : null,
        ];
    }

    private function getLoansUpdates($since, $lastId = 0, $limit = self::CHUNK_SIZE)
    {
        // First, get loan IDs that need updating
        $loanIds = DB::table('loans')
            ->where('id', '>', $lastId)
            ->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('created_at', '>', $since);
            })
            ->orderBy('id')
            ->limit($limit + 1)
            ->pluck('id');

        $hasMore = $loanIds->count() > $limit;
        if ($hasMore) {
            $loanIds = $loanIds->take($limit);
        }

        // Get loans with customer data
        $loans = DB::table('loans')
            ->select([
                'loans.*',
                'customers.uuid as customer_uuid',
                'customers.first_name as customer_first_name',
                'customers.last_name as customer_last_name',
                'customers.phone_number as customer_phone',
                'customers.address as customer_address',
            ])
            ->leftJoin('customers', 'loans.customer_id', '=', 'customers.id')
            ->whereIn('loans.id', $loanIds)
            ->get();

        // Combine the data
        $loansData = $loans->map(function ($loan) {
            return [
                'id' => $loan->id,
                'uuid' => $loan->uuid,
                'pawn_ticket_number' => $loan->pawn_ticket_number,
                'customer_id' => $loan->customer_id,
                'category_id' => $loan->category_id,
                'customer_uuid' => $loan->customer_uuid,
                'category_uuid' => $loan->category_uuid,
                'loan_amount' => (float) $loan->loan_amount,
                'appraisal_value' => (float) $loan->appraisal_value,
                'interest_rate' => (float) $loan->interest_rate,
                'penalty_rate' => (float) $loan->penalty_rate,
                'service_charge' => (float) $loan->service_charge,
                'amount_disbursed' => (float) $loan->amount_disbursed,
                'loan_date' => $loan->loan_date,
                'maturity_date' => $loan->maturity_date,
                'expiry_date' => $loan->expiry_date,
                'loan_period' => $loan->loan_period,
                'loan_period_type' => $loan->loan_period_type,
                'status' => $loan->status,
                'remarks' => $loan->remarks,
                'paid_interest_amount' => (float) $loan->paid_interest_amount,
                'paid_penalty_amount' => (float) $loan->paid_penalty_amount,
                'renewal_date' => $loan->renewal_date,
                'previous_loan_id' => $loan->previous_loan_id,
                'redemption_date' => $loan->redemption_date,
                'forfeiture_date' => $loan->forfeiture_date,
                'created_at' => $loan->created_at,
                'updated_at' => $loan->updated_at,
            ];
        });

        return [
            'items' => $loansData->values(),
            'has_more' => $hasMore,
            'next_id' => $hasMore ? $loanIds->last() : null,
        ];
    }

    private function getItemsUpdates($since, $lastId = 0, $limit = self::CHUNK_SIZE)
    {
        $query = DB::table('items')
            ->select([
                'id', 'uuid', 'customer_id', 'loan_id', 'loan_uuid',
                'category_id', 'category_uuid', 'description', 'condition',
                'appraisal_value', 'storage_location', 'condition_notes',
                'status', 'created_at', 'updated_at', 'market_value',
                'selling_price', 'tag_number', 'forfeiture_date',
                'final_selling_price', 'buyer_name', 'buyer_contact',
                'sale_notes', 'sold_at',
            ])
            ->where('id', '>', $lastId)
            ->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('created_at', '>', $since);
            })
            ->orderBy('id')
            ->limit($limit + 1);

        $items = $query->get();
        $itemsArray = $items->map(function ($item) {
            return [
                'id' => (int) $item->id,
                'uuid' => $item->uuid,
                'customer_id' => (int) $item->customer_id,
                'loan_id' => $item->loan_id ? (int) $item->loan_id : null,
                'loan_uuid' => $item->loan_uuid,
                'category_id' => (int) $item->category_id,
                'category_uuid' => $item->category_uuid,
                'description' => $item->description,
                'condition' => $item->condition,
                'appraisal_value' => (float) $item->appraisal_value,
                'storage_location' => $item->storage_location,
                'condition_notes' => $item->condition_notes,
                'status' => $item->status,
                'market_value' => $item->market_value ? (float) $item->market_value : null,
                'selling_price' => $item->selling_price ? (float) $item->selling_price : null,
                'tag_number' => $item->tag_number,
                'forfeiture_date' => $item->forfeiture_date ? Carbon::parse($item->forfeiture_date)->toISOString() : null,
                'final_selling_price' => $item->final_selling_price ? (float) $item->final_selling_price : null,
                'buyer_name' => $item->buyer_name,
                'buyer_contact' => $item->buyer_contact,
                'sale_notes' => $item->sale_notes,
                'sold_at' => $item->sold_at ? Carbon::parse($item->sold_at)->toISOString() : null,
                'created_at' => $item->created_at,
                'updated_at' => $item->updated_at,
            ];
        })->values();

        $hasMore = $items->count() > $limit;
        if ($hasMore) {
            $itemsArray = $itemsArray->take($limit);
        }

        return [
            'items' => $itemsArray,
            'has_more' => $hasMore,
            'next_id' => $hasMore ? $items[$items->count() - 2]->id : null,
        ];
    }

    private function getCategoriesUpdates($since, $lastId = 0, $limit = self::CHUNK_SIZE)
    {
        $query = DB::table('categories')
            ->select([
                'id', 'uuid', 'name', 'description',
                'loan_period_type', 'loan_period',
                'loan_period_expiry', 'interest_rate',
                'is_renewable', 'penalty_rate',
                'created_at', 'updated_at',
            ])
            ->where('id', '>', $lastId)
            ->where(function ($q) use ($since) {
                $q->where('updated_at', '>', $since)
                  ->orWhere('created_at', '>', $since);
            })
            ->orderBy('id')
            ->limit($limit + 1);

        $categories = $query->get();

        $categoriesArray = $categories->map(function ($category) {
            return [
                'id' => (int) $category->id,
                'uuid' => $category->uuid,
                'name' => $category->name,
                'description' => $category->description,
                'loan_period_type' => $category->loan_period_type,
                'loan_period' => (int) $category->loan_period,
                'loan_period_expiry' => (int) $category->loan_period_expiry,
                'interest_rate' => (float) $category->interest_rate,
                'is_renewable' => (bool) $category->is_renewable,
                'penalty_rate' => (float) $category->penalty_rate,
                'created_at' => $category->created_at,
                'updated_at' => $category->updated_at,
            ];
        })->values();

        $hasMore = $categories->count() > $limit;
        if ($hasMore) {
            $categoriesArray = $categoriesArray->take($limit);
        }

        return [
            'items' => $categoriesArray,
            'has_more' => $hasMore,
            'next_id' => $hasMore ? $categories[$categories->count() - 2]->id : null,
        ];
    }

    // Update getUpdateCounts method to include categories
    private function getUpdateCounts($since)
    {
        $counts = Cache::remember("update_counts_{$since->timestamp}", self::CACHE_TTL, function () use ($since) {
            return [
                'customers' => DB::table('customers')
                    ->where('updated_at', '>', $since)
                    ->count(),
                'loans' => DB::table('loans')
                    ->where('updated_at', '>', $since)
                    ->count(),
                'items' => DB::table('items')
                    ->where('updated_at', '>', $since)
                    ->count(),
                'categories' => DB::table('categories')
                    ->where('updated_at', '>', $since)
                    ->count(),
            ];
        });

        return $counts;
    }
}
