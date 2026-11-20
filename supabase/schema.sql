-- ═══════════════════════════════════════════════════════════════════════════
-- Walammi — Supabase database setup
-- ═══════════════════════════════════════════════════════════════════════════
-- Run this in:  Supabase Dashboard → SQL Editor → New query → paste → Run
--
-- What it does:
--   1. Creates every table, enum, index and foreign key Walammi needs
--      (User, Account, Session, VerificationToken, Series, Part, Comment,
--       Reaction, PartView, AnalyticsEvent)
--   2. Locks every table down with Row Level Security and DENY-all policies,
--      so nobody can read/write your data through the Supabase REST/JS API.
--      The app connects with the service role / direct Postgres connection
--      (DATABASE_URL), which bypasses RLS — readers never use that API.
--
-- Safe to run once on a brand-new project. If you already ran it, either
-- reset the database (Dashboard → Database → Reset) or drop the objects
-- manually before re-running.
-- ═══════════════════════════════════════════════════════════════════════════

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('READER', 'EDITOR', 'ADMIN');

-- CreateEnum
CREATE TYPE "SeriesStatus" AS ENUM ('ONGOING', 'COMPLETED', 'HIATUS');

-- CreateEnum
CREATE TYPE "CommentStatus" AS ENUM ('VISIBLE', 'HIDDEN');

-- CreateEnum
CREATE TYPE "ReactionKind" AS ENUM ('LIKE', 'LOVE', 'WOW', 'SAD', 'FIRE');

-- CreateEnum
CREATE TYPE "EventType" AS ENUM ('PAGE_VIEW', 'READ_START', 'READ_COMPLETE', 'DOWNLOAD_ATTEMPT', 'DOWNLOAD_BLOCKED', 'SIGNUP', 'LOGIN', 'COMMENT_ADDED', 'REACTION_ADDED', 'SEARCH');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,
    "passwordHash" TEXT,
    "role" "Role" NOT NULL DEFAULT 'READER',
    "banned" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "sessionToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "Series" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "coverImage" TEXT,
    "author" TEXT,
    "genre" TEXT,
    "status" "SeriesStatus" NOT NULL DEFAULT 'ONGOING',
    "featured" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Series_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Part" (
    "id" TEXT NOT NULL,
    "seriesId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "pdfUrl" TEXT NOT NULL,
    "pdfKey" TEXT,
    "pageCount" INTEGER,
    "fileSizeKb" INTEGER,
    "summary" TEXT,
    "published" BOOLEAN NOT NULL DEFAULT true,
    "publishedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Part_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Comment" (
    "id" TEXT NOT NULL,
    "partId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "parentId" TEXT,
    "body" TEXT NOT NULL,
    "status" "CommentStatus" NOT NULL DEFAULT 'VISIBLE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Reaction" (
    "id" TEXT NOT NULL,
    "partId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "kind" "ReactionKind" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Reaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PartView" (
    "id" TEXT NOT NULL,
    "partId" TEXT NOT NULL,
    "userId" TEXT,
    "sessionId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PartView_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AnalyticsEvent" (
    "id" TEXT NOT NULL,
    "type" "EventType" NOT NULL,
    "path" TEXT,
    "sessionId" TEXT,
    "userId" TEXT,
    "partId" TEXT,
    "seriesId" TEXT,
    "meta" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AnalyticsEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_sessionToken_key" ON "Session"("sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "Session_userId_sessionToken_key" ON "Session"("userId", "sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON "VerificationToken"("identifier", "token");

-- CreateIndex
CREATE UNIQUE INDEX "Series_slug_key" ON "Series"("slug");

-- CreateIndex
CREATE INDEX "Series_genre_idx" ON "Series"("genre");

-- CreateIndex
CREATE INDEX "Series_featured_idx" ON "Series"("featured");

-- CreateIndex
CREATE INDEX "Part_published_idx" ON "Part"("published");

-- CreateIndex
CREATE UNIQUE INDEX "Part_seriesId_order_key" ON "Part"("seriesId", "order");

-- CreateIndex
CREATE INDEX "Comment_partId_status_createdAt_idx" ON "Comment"("partId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "Reaction_partId_kind_idx" ON "Reaction"("partId", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "Reaction_partId_userId_kind_key" ON "Reaction"("partId", "userId", "kind");

-- CreateIndex
CREATE INDEX "PartView_partId_createdAt_idx" ON "PartView"("partId", "createdAt");

-- CreateIndex
CREATE INDEX "PartView_createdAt_idx" ON "PartView"("createdAt");

-- CreateIndex
CREATE INDEX "AnalyticsEvent_type_createdAt_idx" ON "AnalyticsEvent"("type", "createdAt");

-- CreateIndex
CREATE INDEX "AnalyticsEvent_createdAt_idx" ON "AnalyticsEvent"("createdAt");

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Part" ADD CONSTRAINT "Part_seriesId_fkey" FOREIGN KEY ("seriesId") REFERENCES "Series"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_partId_fkey" FOREIGN KEY ("partId") REFERENCES "Part"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Comment" ADD CONSTRAINT "Comment_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Comment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reaction" ADD CONSTRAINT "Reaction_partId_fkey" FOREIGN KEY ("partId") REFERENCES "Part"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reaction" ADD CONSTRAINT "Reaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PartView" ADD CONSTRAINT "PartView_partId_fkey" FOREIGN KEY ("partId") REFERENCES "Part"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PartView" ADD CONSTRAINT "PartView_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AnalyticsEvent" ADD CONSTRAINT "AnalyticsEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- ═══════════════════════════════════════════════════════════════════════════
-- Row Level Security — deny everything through the Supabase API
-- ═══════════════════════════════════════════════════════════════════════════
-- Walammi talks to Postgres over a direct connection with Prisma (bypasses
-- RLS). These policies make sure the public anon key alone can do NOTHING.
-- (anon/authenticated always exist on Supabase; created if missing so the
-- script also runs on a plain local Postgres for testing.)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END
$$;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'User', 'Account', 'Session', 'VerificationToken',
    'Series', 'Part', 'Comment', 'Reaction', 'PartView', 'AnalyticsEvent'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS "walammi_deny_all_select" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "walammi_deny_all_insert" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "walammi_deny_all_update" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "walammi_deny_all_delete" ON %I', t);
    EXECUTE format('CREATE POLICY "walammi_deny_all_select" ON %I FOR SELECT TO anon, authenticated USING (false)', t);
    EXECUTE format('CREATE POLICY "walammi_deny_all_insert" ON %I FOR INSERT TO anon, authenticated WITH CHECK (false)', t);
    EXECUTE format('CREATE POLICY "walammi_deny_all_update" ON %I FOR UPDATE TO anon, authenticated USING (false)', t);
    EXECUTE format('CREATE POLICY "walammi_deny_all_delete" ON %I FOR DELETE TO anon, authenticated USING (false)', t);
  END LOOP;
END
$$;
