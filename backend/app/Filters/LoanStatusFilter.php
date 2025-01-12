<?php

namespace App\Filters;

use Spatie\QueryBuilder\Filters\Filter;
use Illuminate\Database\Eloquent\Builder;
use App\Enums\LoanStatus;

class LoanStatusFilter implements Filter
{
    public function __invoke(Builder $query, $value, string $property)
    {
        if ($value === 'active') {
            return $query->whereNotIn('status', [LoanStatus::Renewed, LoanStatus::Cancelled]);
        }

        if ($value === 'inactive') {
            return $query->whereIn('status', [LoanStatus::Renewed, LoanStatus::Cancelled]);
        }

        return $query;
    }
}
