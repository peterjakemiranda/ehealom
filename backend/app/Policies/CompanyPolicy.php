<?php

namespace App\Policies;

use App\Models\Company;
use App\Models\User;

class CompanyPolicy
{
    public function view(User $user, Company $company)
    {
        return $user->companies->contains($company->id);
    }

    public function update(User $user, Company $company)
    {
        return $user->companies->contains($company->id);
    }

    public function delete(User $user, Company $company)
    {
        return $user->companies->contains($company->id);
    }
}
