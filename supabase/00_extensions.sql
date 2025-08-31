-- Enable extensions commonly used
create extension if not exists "pgcrypto"; -- gen_random_uuid()
create extension if not exists "uuid-ossp";