cube(`Transactions`, {
  sql: `SELECT * FROM public.transactions`,

  joins: {
    Players: {
      relationship: `belongsTo`,
      sql: `${CUBE}.player_id = ${Players.id}`
    }
  },

  measures: {
    count: {
      type: `count`
    },

    totalAmount: {
      sql: `amount`,
      type: `sum`,
      format: `currency`
    },

    depositVolume: {
      sql: `amount`,
      type: `sum`,
      filters: [
        { sql: `${CUBE}.transaction_type = 'DEPOSIT'` }
      ],
      description: `Governed sum of all completed player deposits`
    },

    withdrawalVolume: {
      sql: `amount`,
      type: `sum`,
      filters: [
        { sql: `${CUBE}.transaction_type = 'WITHDRAWAL'` }
      ],
      description: `Governed sum of all completed player withdrawals`
    }
  },

  dimensions: {
    id: {
      sql: `id`,
      type: `number`,
      primaryKey: true
    },

    transactionType: {
      sql: `transaction_type`,
      type: `string`
    },

    currency: {
      sql: `currency`,
      type: `string`
    },

    createdAt: {
      sql: `created_at`,
      type: `time`
    }
  }
});

