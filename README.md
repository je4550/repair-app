# AutoPlanner.ai - Automotive Repair Shop Management System

A comprehensive multi-tenant SaaS platform for automotive repair shops, supporting single locations and multi-location chains with regional management.

## Features

### Core Functionality
- **Multi-tenant Architecture**: Subdomain-based tenant isolation
- **Hierarchical Organization**: Company → Regions → Locations structure
- **Customer Management**: Track customer information, vehicles, and service history
- **Appointment Scheduling**: Calendar-based appointment system with drag-and-drop
- **Service Management**: Service catalog with pricing and duration
- **Vehicle Management**: Track customer vehicles and service history
- **Communications**: Inbound/outbound message tracking with customers
- **Reporting**: Regional and location-based reporting with aggregation

### User Roles & Permissions
- **Admin**: Full system access, can manage all locations and users
- **Manager**: Location-specific access, can manage users within their location
- **Technician**: Can view and update appointments, limited customer access
- **Receptionist**: Can manage appointments and customers, no user management

### Location Management
- Support for multi-location chains with regional hierarchy
- Location switching for admins and managers
- Data isolation by location
- Cross-location reporting for admins

## Technical Stack

- **Ruby**: 3.2.2
- **Rails**: 7.1.3
- **Database**: PostgreSQL (production), SQLite3 (development)
- **Authentication**: Devise
- **Authorization**: Pundit
- **Multi-tenancy**: acts_as_tenant
- **UI**: Tailwind CSS, Turbo, Stimulus
- **Pagination**: Pagy

## Setup

### Prerequisites
- Ruby 3.2.2
- Rails 7.1.3
- SQLite3 (development) or PostgreSQL (production)
- Node.js and Yarn

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd repair-app
```

2. Install dependencies:
```bash
bundle install
yarn install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Start the server:
```bash
rails server
```

### Development Server

To run the development server accessible from other machines:
```bash
rails server -b 0.0.0.0 -p 3000
```

## Architecture

### Multi-Tenant Structure
```
Shop (Company)
├── Region (e.g., Houston)
│   ├── Location (e.g., Houston North)
│   └── Location (e.g., Houston South)
└── Region (e.g., Dallas)
    ├── Location (e.g., Dallas Downtown)
    └── Location (e.g., Dallas Airport)
```

### Data Scoping
- All operational data (customers, appointments, vehicles) belongs to a Location
- Users are assigned to a specific Location
- Admins can view and switch between all locations
- Managers can only access their assigned location

### Key Models
- **Shop**: The parent company/tenant
- **Region**: Geographic regions within a company
- **Location**: Individual shop locations
- **User**: System users with role-based permissions
- **Customer**: Shop customers
- **Vehicle**: Customer vehicles
- **Appointment**: Service appointments
- **Service**: Available services catalog
- **Communication**: Customer communications log

## Usage

### Accessing the Application
- Main domain: Access the marketing/landing page
- Subdomain access: `<shop-subdomain>.domain.com` - Direct shop access
- User login: Automatically routes to correct shop based on user's location

### User Management
- Admins can create users in any location
- Managers can only create/manage users in their assigned location
- Location switching (admin/manager) only affects operational data viewing
- User management always restricted to assigned permissions

### Location Switching
Admins and managers can switch between locations to view data:
1. Use the location dropdown in the dashboard
2. Affects: customers, appointments, vehicles, services
3. Does not affect: user management permissions

## Security

- Tenant isolation via acts_as_tenant
- Role-based access control with Pundit policies
- Secure session management
- CSRF protection
- SQL injection prevention through ActiveRecord

## Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb
```

## Deployment

The application is configured for deployment on standard Rails hosting platforms. Environment-specific configurations:

- `config/environments/production.rb`: Production settings
- `config/database.yml`: Database configuration
- Environment variables needed:
  - `DATABASE_URL`: PostgreSQL connection string
  - `SECRET_KEY_BASE`: Rails secret key
  - `RAILS_MASTER_KEY`: For credentials encryption

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.