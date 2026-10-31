cube(`Players`, {
  sql: `SELECT * FROM public.players`,

  measures: {
    count: {
      type: `count`,
      description: `Total unique registered player accounts`
    }
  },

  dimensions: {
    id: {
      sql: `id`,
      type: `number`,
      primaryKey: true
    },

    username: {
      sql: `username`,
      type: `string`
    },

    country: {
      sql: `country`,
      type: `string`,
      description: `Country code of player regulatory jurisdiction (e.g. SE, UK, MT, BR)`
    },

    riskTier: {
      sql: `risk_tier`,
      type: `string`
    },

    createdAt: {
      sql: `created_at`,
      type: `time`
    }
  }
});

