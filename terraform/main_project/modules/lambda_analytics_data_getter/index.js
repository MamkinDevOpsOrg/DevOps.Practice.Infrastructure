import { Client } from 'pg';

export const handler = async () => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: {
      rejectUnauthorized: false,
    },
  });

  try {
    await client.connect();

    const pageHitResult = await client.query(`
      SELECT 
        us.user_id,
        ph.session_id,
        ph.hit_id,
        ph.url,
        ph.referrer,
        ph.user_agent,
        ph.timestamp
      FROM page_hit ph
      JOIN user_session us ON ph.session_id = us.session_id;
    `);

    const pageClickResult = await client.query(`
      SELECT 
        us.user_id,
        pc.session_id,
        pc.click_id,
        pc.url,
        pc.element_id,
        pc.element_class,
        pc.element_text,
        pc.timestamp
      FROM page_click pc
      JOIN user_session us ON pc.session_id = us.session_id;
    `);

    return {
      statusCode: 200,
      body: JSON.stringify({
        page_hit: pageHitResult.rows,
        page_click: pageClickResult.rows,
      }),
    };
  } catch (error) {
    console.error('❌ Error reading data from database:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  } finally {
    await client.end();
  }
};
