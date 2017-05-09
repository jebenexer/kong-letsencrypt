return {
  {
    name = "2017-05-07-194900_acme_challenge",
    up = [[
      CREATE TABLE IF NOT EXISTS acme_challenge(
      domain text UNIQUE,
      token text UNIQUE,
      payload text,
      created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
      PRIMARY KEY (domain)
      );

      DO $$
      BEGIN
      IF (SELECT to_regclass('public.acme_challenge_token_idx')) IS NULL THEN
      CREATE INDEX acme_challenge_token_idx ON acme_challenge(token);
      END IF;
      END$$;
      ]],
    down = [[
      DROP TABLE acme_challenge;
      ]]
  }
}
