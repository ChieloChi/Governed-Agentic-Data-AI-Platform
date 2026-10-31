cube(`GameSessions`, {
  sql: `SELECT * FROM public.game_sessions`,

  joins: {
    Players: {
      relationship: `belongsTo`,
      sql: `${CUBE}.player_id = ${Players.id}`
    }
  },

  measures: {
    totalBets: {
      sql: `bet_amount`,
      type: `sum`,
      format: `currency`
    },

    totalWins: {
      sql: `win_amount`,
      type: `sum`,
      format: `currency`
    },

    // 💡 THE GOVERNED REVENUE METRIC (Gross Gaming Revenue = Total Bets - Total Wins)
    grossGamingRevenue: {
      sql: `${totalBets} - ${totalWins}`,
      type: `number`,
      format: `currency`,
      description: `Governed Gross Gaming Revenue (GGR). Mathematical definition: Total Bets minus Player Payouts.`
    }
  },

  dimensions: {
    id: {
      sql: `id`,
      type: `number`,
      primaryKey: true
    },

    gameCategory: {
      sql: `game_category`,
      type: `string`
    },

    createdAt: {
      sql: `created_at`,
      type: `time`
    }
  }
});

