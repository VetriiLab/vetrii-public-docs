# Vetrii Backend

A Web3 vehicle history tokenization platform that creates immutable digital passports for vehicles on multiple blockchain networks.

## Overview

Vetrii is a blockchain-based platform for vehicle lifecycle management and history tokenization. The system creates NFT-based digital passports for vehicles, storing their history and metadata on IPFS while registering ownership on multiple blockchain networks.

## Key Features

- **Digital Passports**: Create NFT-based digital identities for vehicles with immutable history records
- **Multi-Chain Support**: Deploy vehicle passports across multiple blockchain networks (Polygon, Ethereum, etc.)
- **Web3 Integration**: Full blockchain integration using Viem for smart contract interactions
- **IPFS Storage**: Decentralized metadata storage via Pinata for vehicle information and documents
- **Vehicle History Tracking**: Immutable event logging for vehicle lifecycle (maintenance, ownership transfers, accidents, etc.)
- **NFC Stickers**: Physical-to-digital bridge with NFC sticker integration for vehicle authentication
- **Authentication System**: JWT-based auth with Google OAuth support
- **Queue Management**: Background job processing with BullMQ and Redis
- **Email Notifications**: User notifications via MailGun with development testing via Mailpit
- **API Documentation**: Interactive Swagger UI for API exploration and testing

## Technology Stack

### Core Framework

- **NestJS 10**: TypeScript-based Node.js framework
- **TypeORM**: Database ORM with migration support
- **MySQL 8.0**: Primary database

### Blockchain & Web3

- **Viem 2.x**: Modern Web3 library for Ethereum interactions
- **Multi-chain support**: Configurable blockchain network support
- **Smart Contracts**: NFT minting and management via custom registry contracts

### Storage & Files

- **Pinata SDK 2.x**: IPFS pinning and gateway services
- **IPFS**: Decentralized storage for vehicle metadata and documents
- **Strategy Pattern**: Extensible provider architecture for multiple IPFS providers

### Authentication & Security

- **JWT**: Token-based authentication
- **Passport.js**: Strategy-based authentication (Local, JWT, Google OAuth)
- **bcryptjs**: Password hashing
- **Request throttling**: Rate limiting protection

### Background Processing

- **BullMQ**: Queue management for background jobs
- **Redis**: Queue storage and caching
- **Event Emitter**: Internal event-driven architecture

### Development & Deployment

- **Docker & Docker Compose**: Containerized development and deployment
- **pnpm**: Fast, disk space efficient package manager
- **TypeScript**: Type-safe development
- **ElasticMQ**: Local AWS SQS simulation for development

## Project Structure

```
src/
├── auth/                      # Authentication & authorization
│   ├── services/             # Auth service, OTP service
│   └── strategies/           # JWT, Google OAuth strategies
├── users/                    # User management
├── wallets/                  # Blockchain wallet management
├── viem/                     # Web3 blockchain integration
│   ├── services/            # Contract calls, multi-chain support
│   ├── config/              # Chain registry configuration
│   ├── abi/                 # Smart contract ABIs
│   └── types/               # TypeScript interfaces
├── ipfs/                     # IPFS integration
│   ├── strategies/          # Pinata and other provider implementations
│   ├── services/            # Upload and metadata services
│   ├── entities/            # IPFS metadata entity
│   └── interfaces/          # Provider interfaces
├── digital-passports/        # NFT digital passport management
│   ├── dto/                 # Data transfer objects
│   └── services/            # Passport creation and retrieval
├── vehicles/                 # Vehicle data management
│   ├── services/            # Vehicle data fetching and processing
│   └── dto/                 # Vehicle DTOs
├── vehicle-history-events/   # Vehicle lifecycle event tracking
├── stickers/                 # NFC sticker management
├── stickers-v2/              # Enhanced sticker functionality
├── brands/                   # Vehicle brand catalog
├── models/                   # Vehicle model catalog
├── versions/                 # Vehicle version catalog
├── owners/                   # Vehicle ownership tracking
├── referral/                 # Referral system
├── mail/                     # Email services
│   └── services/            # Email templates and sending
├── database/                 # Database configuration
│   ├── entities/            # TypeORM entities
│   ├── migrations/          # Database migrations
│   └── seeds/               # Database seeders
├── config/                   # Application configuration
│   ├── queue/               # BullMQ configuration
│   └── cache/               # Redis cache configuration
├── common/                   # Shared utilities
│   ├── filters/             # Exception filters
│   ├── interceptors/        # Request/response interceptors
│   ├── guards/              # Authorization guards
│   └── dto/                 # Shared DTOs
└── main.ts                   # Application entry point
```

## Requirements

- Node.js ≥ 20
- pnpm ≥ 10.15.1
- MySQL 8.0+
- Docker and Docker Compose (recommended)
- Redis (for queue management)

## Installation

The installation (pnpm install) is done automatically inside the Docker container.

**Note:** When package.json is updated, rebuild the Docker container with `docker compose up -d --build`.

**Note:** When .env is updated, restart the container with `docker compose restart app`.

## Configuration

### Environment Variables

1. Create a `.env` file based on `.env.example`
2. Configure the following key variables:

#### Database Configuration

```bash
DB_HOST=db
DB_PORT=3306
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password
DB_DATABASE=vetrii
```

#### JWT Authentication

```bash
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d
```

#### Google OAuth

```bash
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=http://localhost:8000/auth/google/callback
```

#### Blockchain (Viem)

```bash
# Multi-chain configuration - see src/viem/config for details
VIEM_PRIVATE_KEY=your_minter_private_key
VIEM_DEFAULT_CHAIN=137  # Polygon Mainnet

# Chain-specific RPC URLs
VIEM_RPC_URL_137=https://polygon-rpc.com
# Add more chains as needed
```

#### IPFS (Pinata)

```bash
IPFS_PROVIDER=pinata
PINATA_JWT=your_pinata_jwt_token
PINATA_GATEWAY=your-gateway.mypinata.cloud
IPFS_MAX_FILE_SIZE=52428800  # 50MB
```

#### Email (Smtp/Mailpit)

```bash
MAIL_PROVIDER=mailpit # or smtp
MAILPIT_HOST=mailpit # docker container name
FORWARD_MAILPIT_PORT=1025
FORWARD_MAILPIT_DASHBOARD_PORT=8025
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
SMTP_SECURE=
SMTP_IGNORE_TLS=
```

#### Redis & Queue

```bash
REDIS_HOST=redis
REDIS_PORT=6379
```

#### AWS SQS (Development uses ElasticMQ)

```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local
SQS_ENDPOINT=http://elasticmq:9324
```

## Development

### Start the Application

```bash
# Start all services with Docker
docker compose up -d

# View logs
docker compose logs -f app

# First time setup (create database tables)
pnpm migration:run:docker # docker compose exec app pnpm migration:run
docker compose restart app
```

The application will be available at:

- **API**: http://localhost:8000
- **Swagger Documentation**: http://localhost:8000/api
- **Mailpit (Email Testing)**: http://localhost:8025
- **ElasticMQ UI**: http://localhost:9325

### Available Services

The Docker Compose setup includes:

- **app**: NestJS application
- **db**: MySQL 8.0 database
- **redis**: Redis for caching and queues
- **mailpit**: Email testing interface
- **elasticmq**: Local AWS SQS simulation

## Database Management

### Migrations

Migrations are the primary and recommended method for managing database schema changes. The system is configured to automatically execute pending migrations during application startup.

#### Docker Commands

```bash
# Run pending migrations
docker compose exec app pnpm migration:run

# Revert last migration
docker compose exec app pnpm migration:revert

# Show applied migrations
docker compose exec app pnpm migration:show
```

#### Local Commands

```bash
# Run pending migrations
pnpm migration:run:docker

# Revert last migration
pnpm migration:revert:docker

# Show applied migrations
pnpm migration:show:docker
```

## Core Modules

### Viem Module (Blockchain Integration)

The Viem module provides Web3 functionality for interacting with multiple blockchain networks.

**Key Features:**

- Multi-chain support (Polygon, Ethereum, testnets)
- Smart contract interaction for NFT minting
- Wallet client management
- Contract verification and role checking
- Configurable chain registry

**Services:**

- `ViemService`: Legacy single-chain service (backward compatibility)
- `MultiChainViemService`: Multi-chain client management
- `MultiChainContractService`: Cross-chain contract operations
- `ContractCallsService`: Smart contract interaction layer
- `ChainRegistryService`: Chain configuration management

### IPFS Module (Decentralized Storage)

The IPFS module handles decentralized file storage using a strategy pattern for provider flexibility.

**Key Features:**

- Strategy pattern for multiple IPFS providers
- Primary provider with fallback support
- Metadata tracking in database
- File validation (size, type, security)
- Upload service with enhanced features

**Current Providers:**

- Pinata (production-ready, JWT authentication)

**Services:**

- `IpfsService`: Main IPFS orchestration service
- `PinataStrategy`: Pinata implementation
- File metadata tracking and retrieval

### Digital Passports Module

Core module for creating and managing vehicle NFT passports.

**Key Features:**

- Create digital passports on single or multiple chains
- NFT minting with vehicle metadata
- Integration with smart contracts
- Vehicle history tracking
- Multi-chain deployment support

**Key Endpoints:**

- `POST /digital-passports`: Create a new digital passport
- `POST /digital-passports/multi-chain`: Create passports on multiple chains
- `GET /digital-passports/:id`: Get passport details
- `GET /digital-passports/chains`: List available blockchain networks

### Vehicles Module

Manages vehicle data and lifecycle.

**Key Features:**

- Vehicle data fetching from external APIs
- Vehicle registration and tracking
- Integration with digital passports
- History event management
- NFC sticker assignment

### Authentication Module

JWT and OAuth-based authentication system.

**Key Features:**

- Email/password registration and login
- Google OAuth integration
- JWT token generation and validation
- Email verification via OTP
- Referral system integration

**Strategies:**

- Local strategy (email/password)
- JWT strategy (bearer token)
- Google OAuth 2.0 strategy

## API Documentation

Interactive API documentation is available via Swagger UI when the application is running:

**Access Swagger UI**: http://localhost:8000/api

The Swagger interface provides:

- Complete API endpoint documentation
- Request/response schemas
- Interactive testing capability
- Authentication support (JWT Bearer tokens)
- OAuth flow testing

## Smart Contracts

The platform interacts with custom smart contracts for NFT minting:

**Contract: VetriiRegistry**

- NFT registry for vehicle digital passports
- Role-based access control (MINTER_ROLE)
- Transferable/non-transferable token support
- Metadata URI management

**ABI Location**: `src/viem/abi/VetriiRegistry.sol/VetriiRegistry.json`

## Error Handling

The application uses centralized error handling:

- `GlobalExceptionFilter`: Catches all unhandled exceptions
- `HttpExceptionFilter`: HTTP-specific error formatting
- Structured error responses with status codes
- Request logging via `LoggingInterceptor`
- Bugsnag integration for production error tracking

## Security Features

- JWT token-based authentication
- Password hashing with bcryptjs
- Request rate limiting (throttling)
- CORS configuration
- Input validation with class-validator
- SQL injection protection (TypeORM)
- File upload validation
- Role-based access control

## Monitoring & Logging

- Structured logging with NestJS Logger
- Request/response logging
- Database query logging (development)
- Error tracking with Bugsnag (production/staging)
- Health checks for Docker services

## Contributing

1. Follow NestJS best practices and design patterns
2. Use TypeScript strict mode
3. Write unit tests for new features
4. Update API documentation (Swagger decorators)
5. Follow the existing code style
6. Create migrations for database changes
7. Update this README for significant changes

## Troubleshooting

### Common Issues

**Database connection fails:**

```bash
# Check if database is running
docker compose ps db

# Check database logs
docker compose logs db
```

**Blockchain connection fails:**

- Verify RPC URLs are accessible
- Check private key has sufficient gas
- Ensure contract addresses are correct for the network

**IPFS upload fails:**

- Verify Pinata JWT token is valid
- Check file size limits
- Ensure network connectivity to Pinata

**Container won't start:**

```bash
# Rebuild containers
docker compose down
docker compose up -d --build

# Check logs
docker compose logs -f app
```

## Architecture Decisions

### Why Viem over Web3.js or ethers.js?

- Modern TypeScript-first design
- Better tree-shaking and bundle size
- Type-safe contract interactions
- Active maintenance and development

### Why Strategy Pattern for IPFS?

- Easy to add new providers (Infura, local nodes)
- Fallback support for reliability
- Provider-agnostic business logic
- Testability with mock providers

### Why NestJS?

- Enterprise-grade TypeScript framework
- Built-in dependency injection
- Excellent testing support
- Modular architecture
- Strong TypeScript integration

## License

This project is licensed under the MIT License - see the LICENSE file for details.
