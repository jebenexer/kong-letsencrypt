return {
  {
    name = "2017-05-07-194900_acme_challenge",
    up =  [[
      CREATE TABLE IF NOT EXISTS acme_challenge(
      domain text,
      token text,
      payload text,
      created_at timestamp,
      PRIMARY KEY (domain)
      );

      CREATE INDEX IF NOT EXISTS ON acme_challenge(token);
      ]],
    down = [[
      DROP TABLE acme_challenge;
      ]]
  }
}
