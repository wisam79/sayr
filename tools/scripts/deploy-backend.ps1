#!/usr/bin/env pwsh
# Sayr v3 Backend Deployment Script
# Usage: .\deploy-backend.ps1

$ErrorActionPreference = "Stop"

$ProjectRef = "cdydfiiufaebljfduybx"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sayr v3 Backend Deployment" -ForegroundColor Cyan
Write-Host "Project: $ProjectRef" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check supabase login
Write-Host "`n[1/4] Checking Supabase CLI auth..." -ForegroundColor Green
$login = supabase projects list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   You need to login first: supabase login" -ForegroundColor Red
    exit 1
}

# Link
Write-Host "`n[2/4] Linking to project $ProjectRef..." -ForegroundColor Green
supabase link --project-ref $ProjectRef

# Push migrations
Write-Host "`n[3/4] Pushing 22 database migrations..." -ForegroundColor Green
supabase db push

# Deploy functions
Write-Host "`n[4/4] Deploying 6 Edge Functions..." -ForegroundColor Green
$functions = @(
    "send-push-notification",
    "process-payment",
    "sync-offline-locations",
    "emergency-alert",
    "generate-driver-report",
    "trip-status-webhook"
)

foreach ($fn in $functions) {
    Write-Host "   Deploying $fn..." -NoNewline
    supabase functions deploy $fn 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
