const { Client } = require('pg');

let client;

async function connectToDatabase() {
  if (!client) {
    client = new Client({
      host: process.env.DB_HOST,
      port: 5432,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });
    await client.connect();
  }
}

exports.handler = async (event) => {
  try {
    await connectToDatabase();

    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({ error: 'Method Not Allowed' }),
      };
    }

    const body = JSON.parse(event.body);

    if (!body.event_type) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing event_type' }),
      };
    }

    const { session_id, user_id } = body;

    if (!session_id || !user_id) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing session_id or user_id' }),
      };
    }

    await client.query(
      `
      INSERT INTO user_session (session_id, user_id)
      VALUES ($1, $2)
      ON CONFLICT (session_id) DO NOTHING
    `,
      [session_id, user_id]
    );

    if (body.event_type === 'page_hit') {
      const { hit_id, url, referrer, user_agent, timestamp } = body;

      await client.query(
        `
        INSERT INTO page_hit (hit_id, session_id, url, referrer, user_agent, timestamp)
        VALUES ($1, $2, $3, $4, $5, $6)
      `,
        [hit_id, session_id, url, referrer, user_agent, timestamp]
      );
    } else if (body.event_type === 'page_click') {
      const {
        click_id,
        url,
        element_id,
        element_class,
        element_text,
        timestamp,
      } = body;

      await client.query(
        `
        INSERT INTO page_click (click_id, session_id, url, element_id, element_class, element_text, timestamp)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `,
        [
          click_id,
          session_id,
          url,
          element_id,
          element_class,
          element_text,
          timestamp,
        ]
      );
    } else {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Unknown event_type' }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Event processed successfully' }),
    };
  } catch (err) {
    console.error('❌ Lambda error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Internal Server Error',
        details: err.message,
      }),
    };
  }
};
