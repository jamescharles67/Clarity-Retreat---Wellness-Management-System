# Clarity Retreat & Wellness Management System

A comprehensive smart contract system built on Clarity for managing retreat centers and wellness facilities. This system provides transparent, secure, and efficient management of programs, instructors, participants, and outcomes.

## System Overview

The system consists of five interconnected smart contracts:

### 1. Retreat Center Management (`retreat-center.clar`)
- Core facility management and administration
- Owner and staff role management
- Facility capacity and resource tracking
- Revenue and financial management

### 2. Instructor Certification System (`instructor-certification.clar`)
- Instructor registration and verification
- Certification tracking and validation
- Specialization and skill management
- Performance and rating systems

### 3. Participant Management (`participant-management.clar`)
- Participant registration and profiles
- Health and safety requirement tracking
- Emergency contact management
- Privacy and data protection compliance

### 4. Program Scheduling (`program-scheduling.clar`)
- Program creation and scheduling
- Instructor assignment and availability
- Capacity management and booking
- Pricing and payment coordination

### 5. Outcome Tracking (`outcome-tracking.clar`)
- Program effectiveness measurement
- Participant feedback and ratings
- Long-term wellness outcome tracking
- Data analytics and reporting

## Key Features

- **Transparent Pricing**: All costs and fees are recorded on-chain
- **Certified Instructors**: Verification system ensures qualified instruction
- **Health & Safety**: Comprehensive tracking of participant requirements
- **Secure Data**: Privacy-focused design with selective data sharing
- **Outcome Measurement**: Track program effectiveness and participant wellness
- **Flexible Scheduling**: Dynamic program scheduling with real-time availability

## Smart Contract Architecture

\`\`\`
┌─────────────────────┐    ┌──────────────────────┐
│  Retreat Center     │────│ Instructor Cert     │
│  Management         │    │ System               │
└─────────────────────┘    └──────────────────────┘
│                           │
│                           │
┌─────────────────────┐    ┌──────────────────────┐
│  Program            │────│ Participant          │
│  Scheduling         │    │ Management           │
└─────────────────────┘    └──────────────────────┘
│                           │
└───────────┐   ┌───────────┘
│   │
┌──────────────────────┐
│  Outcome Tracking    │
│  System              │
└──────────────────────┘
\`\`\`

## Installation & Setup

1. **Install Clarinet**:
   \`\`\`bash
   curl -L https://github.com/hirosystems/clarinet/releases/download/v1.8.0/clarinet-linux-x64.tar.gz | tar xz
   \`\`\`

2. **Install Dependencies**:
   \`\`\`bash
   npm install
   \`\`\`

3. **Run Tests**:
   \`\`\`bash
   npm test
   clarinet test
   \`\`\`

4. **Check Contracts**:
   \`\`\`bash
   clarinet check
   \`\`\`

## Usage Examples

### Register a New Retreat Center
```clarity
(contract-call? .retreat-center register-center 
  "Peaceful Mountain Retreat" 
  "A serene mountain retreat center" 
  u50 ;; capacity
  u1000000) ;; daily-rate in micro-STX
