export const LoanStatus = {
    Draft: 0,
    Active: 1,
    Renewed: 2,
    Redeemed: 3,
    Forfeited: 4,
    Cancelled: 5
  } as const;
  
  type LoanStatus = typeof LoanStatus[keyof typeof LoanStatus];
  
  export const loanStatusProperties = {
    Draft: {
      value: 0,
      label: 'Draft',
      badgeClass: 'badge-ghost'
    },
    Active: {
      value: 1,
      label: 'Active',
      badgeClass: 'badge-primary'
    },
    Renewed: {
      value: 2,
      label: 'Renewed',
      badgeClass: 'badge-info'
    },
    Redeemed: {
      value: 3,
      label: 'Redeemed',
      badgeClass: 'badge-success'
    },
    Forfeited: {
      value: 4,
      label: 'Forfeited',
      badgeClass: 'badge-error'
    },
    Cancelled: {
      value: 5,
      label: 'Cancelled',
      badgeClass: 'badge-warning'
    }
  };
  
  export default LoanStatus;