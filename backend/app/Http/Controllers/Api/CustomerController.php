<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Http\Requests\StoreCustomerRequest;
use App\Http\Requests\UpdateCustomerRequest;
use Illuminate\Http\Request;
use App\Http\Resources\CustomerResource;
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $query = QueryBuilder::for(Customer::class)
            ->allowedFilters([
                AllowedFilter::callback('search', function ($query, $value) {
                    $query->where(function($q) use ($value) {
                        $terms = preg_split('/\s+/', $value);
                        
                        foreach ($terms as $term) {
                            $q->where(function($subQ) use ($term) {
                                $subQ->where('first_name', 'like', "%{$term}%")
                                    ->orWhere('last_name', 'like', "%{$term}%")
                                    ->orWhere('phone_number', 'like', "%{$term}%")
                                    ->orWhere('email', 'like', "%{$term}%")
                                    ->orWhere('id_number', 'like', "%{$term}%");
                            });
                        }
                    });
                }),
                AllowedFilter::exact('id'),
                AllowedFilter::exact('uuid'),
            ])
            ->allowedSorts(['first_name', 'last_name', 'created_at'])
            ->defaultSort('last_name');
    
        // Add search functionality
        if ($request->has('search') && $request->search !== null) {
            $searchTerm = $request->search;
            $query->where(function($q) use ($searchTerm) {
                $q->where('first_name', 'like', "%{$searchTerm}%")
                  ->orWhere('last_name', 'like', "%{$searchTerm}%")
                  ->orWhere('phone_number', 'like', "%{$searchTerm}%")
                  ->orWhere('email', 'like', "%{$searchTerm}%")
                  ->orWhere('id_number', 'like', "%{$searchTerm}%");
            });
        }
    
        $customers = $query->paginate($request->input('per_page', 10));
        
        return CustomerResource::collection($customers);
    }
    
    public function store(StoreCustomerRequest $request)
    {
        $customer = Customer::create($request->validated());
        return new CustomerResource($customer);
    }

    public function show(Customer $customer)
    {
        return new CustomerResource($customer);
    }    

    public function update(UpdateCustomerRequest $request, Customer $customer)
    {
        $customer->update($request->validated());
        return new CustomerResource($customer);
    }

    public function destroy(Customer $customer)
    {
        $customer->delete();
        return response()->json(null, 204);
    }
}
