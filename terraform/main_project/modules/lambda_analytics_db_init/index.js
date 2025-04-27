import { Client } from 'pg';

export const handler = async () => {
  const client = new Client({
    host: process.env.DB_HOST,
    port: 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();

    console.log('✅ Connected to database');

    await client.query(`
      CREATE TABLE IF NOT EXISTS user_session (
        session_id CHAR(36) NOT NULL PRIMARY KEY,
        user_id CHAR(36) NOT NULL
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS page_hit (
        hit_id CHAR(36) NOT NULL PRIMARY KEY,
        session_id CHAR(36) NOT NULL,
        url VARCHAR(2048) NOT NULL,
        referrer VARCHAR(2048),
        user_agent TEXT,
        timestamp TIMESTAMP(3) NOT NULL,
        FOREIGN KEY (session_id) REFERENCES user_session(session_id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS page_click (
        click_id CHAR(36) NOT NULL PRIMARY KEY,
        session_id CHAR(36) NOT NULL,
        url VARCHAR(2048) NOT NULL,
        element_id VARCHAR(255),
        element_class VARCHAR(255),
        element_text VARCHAR(255),
        timestamp TIMESTAMP(3) NOT NULL,
        FOREIGN KEY (session_id) REFERENCES user_session(session_id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      );
    `);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Tables created successfully' }),
    };
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  } finally {
    await client.end();
  }
};
