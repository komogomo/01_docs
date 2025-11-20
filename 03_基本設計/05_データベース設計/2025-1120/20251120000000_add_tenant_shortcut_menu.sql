-- ============================================
-- Migration: Add tenant_shortcut_menu table
-- Created: 2025-11-20
-- Purpose: テナント別フッターショートカットメニュー構成管理
-- ============================================

-- Create ENUM for shortcut feature keys
CREATE TYPE "shortcut_feature_key" AS ENUM (
  'home',
  'board',
  'facility',
  'mypage',
  'logout'
);

-- Create tenant_shortcut_menu table
CREATE TABLE "tenant_shortcut_menu" (
    "id" TEXT NOT NULL,
    "tenant_id" TEXT NOT NULL,
    "feature_key" "shortcut_feature_key" NOT NULL,
    "label_key" TEXT NOT NULL,
    "icon" TEXT NOT NULL,
    "display_order" INTEGER NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "status" "status" NOT NULL DEFAULT 'active',

    CONSTRAINT "tenant_shortcut_menu_pkey" PRIMARY KEY ("id")
);

-- Create unique index on tenant_id and feature_key
CREATE UNIQUE INDEX "tenant_shortcut_menu_tenant_id_feature_key_key" 
ON "tenant_shortcut_menu"("tenant_id", "feature_key");

-- Create index for display order queries
CREATE INDEX "tenant_shortcut_menu_tenant_id_display_order_idx" 
ON "tenant_shortcut_menu"("tenant_id", "display_order");

-- Add foreign key constraint
ALTER TABLE "tenant_shortcut_menu" 
ADD CONSTRAINT "tenant_shortcut_menu_tenant_id_fkey" 
FOREIGN KEY ("tenant_id") 
REFERENCES "tenants"("id") 
ON DELETE RESTRICT 
ON UPDATE CASCADE;
