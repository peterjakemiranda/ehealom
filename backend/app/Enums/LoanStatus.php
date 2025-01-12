<?php

declare(strict_types=1);

namespace App\Enums;

enum LoanStatus: int
{
    case Draft = 0;
    case Active = 1;
    case Renewed = 2;
    case Redeemed = 3;
    case Forfeited = 4;
    case Cancelled = 5;

    public function label(): string
    {
        return match ($this) {
            self::Draft => 'Draft',
            self::Active => 'New',
            self::Renewed => 'Renewed',
            self::Redeemed => 'Redeemed',
            self::Forfeited => 'Forfeited',
            self::Cancelled => 'Cancelled',
        };
    }
}
