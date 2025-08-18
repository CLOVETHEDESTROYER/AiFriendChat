# Onboarding Endpoints Documentation

## Overview

The onboarding system guides new users through a 4-step process to set up their speech assistant account. This document provides comprehensive endpoint documentation for frontend integration.

## Base URL
All endpoints are relative to your API base URL (e.g., `https://your-api.com` or `http://localhost:5050` for development).

## Authentication
All onboarding endpoints require authentication via Bearer token in the Authorization header:

## Onboarding Flow Overview

The onboarding process consists of 4 sequential steps:

1. **Phone Setup** - Provision a Twilio phone number
2. **Calendar Connection** - Connect Google Calendar (optional)
3. **Scenario Creation** - Create first AI scenario
4. **Welcome Call** - Make a test call to complete onboarding

## Core Onboarding Endpoints

### 1. Get Onboarding Status

**Endpoint:** `GET /onboarding/status`

**Description:** Get the current onboarding status and progress for the authenticated user.

**Response:**
```json
{
  "userId": 123,
  "currentStep": "phone_setup",
  "completionPercentage": 25,
  "steps": {
    "phoneSetup": {
      "completed": false,
      "available": true,
      "title": "Set Up Phone Number",
      "description": "Get your dedicated Twilio phone number for making AI calls"
    },
    "calendar": {
      "completed": false,
      "available": false,
      "title": "Connect Google Calendar",
      "description": "Link your calendar to schedule AI calls from events"
    },
    "scenarios": {
      "completed": false,
      "available": false,
      "title": "Create Your First Scenario",
      "description": "Design an AI persona for your calls"
    },
    "welcomeCall": {
      "completed": false,
      "available": false,
      "title": "Make Your First Call",
      "description": "Test your setup with a practice call"
    }
  },
  "isComplete": false,
  "startedAt": "2024-01-15T10:30:00Z",
  "completedAt": null
}
```

### 2. Get Next Action

**Endpoint:** `GET /onboarding/next-action`

**Description:** Get the next recommended action for the user based on their current onboarding step.

**Response:**
```json
{
  "title": "Set Up Your Phone Number",
  "description": "Choose and provision a phone number for your AI assistant",
  "action": "setup_phone",
  "endpoint": "/twilio/search-numbers",
  "priority": "high"
}
```

### 3. Complete Onboarding Step

**Endpoint:** `POST /onboarding/complete-step`

**Description:** Mark a specific onboarding step as completed.

**Request Body:**
```json
{
  "step": "phone_setup"
}
```

**Valid Steps:** `phone_setup`, `calendar`, `scenarios`, `welcome_call`

**Response:** Returns updated onboarding status (same format as GET /onboarding/status)

### 4. Initialize Onboarding

**Endpoint:** `POST /onboarding/initialize`

**Description:** Initialize onboarding for a user (typically called after registration).

**Response:** Returns initial onboarding status

### 5. Check Step Completion

**Endpoint:** `GET /onboarding/check-step/{step}`

**Description:** Check if a specific onboarding step has been completed.

**Parameters:**
- `step` (path) - One of: `phone_setup`, `calendar`, `scenarios`, `welcome_call`

**Response:**
```json
{
  "step": "phone_setup",
  "completed": true
}
```

## Step-Specific Endpoints

### Phone Setup (Step 1)

#### Search Available Numbers
**Endpoint:** `POST /twilio/search-numbers`

**Request Body:**
```json
{
  "area_code": "415",
  "limit": 10
}
```

**Response:**
```json
{
  "availableNumbers": [
    {
      "phoneNumber": "+14155551234",
      "friendlyName": "San Francisco",
      "capabilities": {
        "voice": true,
        "sms": true
      },
      "locality": "San Francisco",
      "region": "CA"
    }
  ]
}
```

#### Provision Phone Number
**Endpoint:** `POST /twilio/provision-number`

**Request Body:**
```json
{
  "phone_number": "+14155551234"
}
```

**Response:**
```json
{
  "phoneNumber": "+14155551234",
  "sid": "PN1234567890abcdef",
  "message": "Phone number +14155551234 provisioned successfully"
}
```

#### Get User Phone Numbers
**Endpoint:** `GET /twilio/user-numbers`

**Response:**
```json
[
  {
    "sid": "PN1234567890abcdef",
    "phoneNumber": "+14155551234",
    "friendlyName": "My AI Assistant Number",
    "capabilities": {
      "voice": true,
      "sms": true
    },
    "dateCreated": "2024-01-15T10:30:00Z",
    "isActive": true
  }
]
```

### Calendar Connection (Step 2)

#### Start Google Calendar Auth
**Endpoint:** `GET /google-calendar/auth`

**Response:**
```json
{
  "authorization_url": "https://accounts.google.com/oauth2/auth?..."
}
```

**Usage:** Redirect user to the authorization_url to complete OAuth flow.

#### Get Calendar Events
**Endpoint:** `GET /google-calendar/events`

**Query Parameters:**
- `max_results` (optional) - Maximum number of events (default: 10)
- `days_ahead` (optional) - Days to look ahead (default: 7)

**Response:**
```json
[
  {
    "id": "event123",
    "summary": "Team Meeting",
    "start": "2024-01-16T14:00:00Z",
    "end": "2024-01-16T15:00:00Z",
    "location": "Conference Room A",
    "description": "Weekly team sync"
  }
]
```

### Scenario Creation (Step 3)

#### Create Custom Scenario
**Endpoint:** `POST /realtime/custom-scenario`

**Request Body:**
```json
{
  "persona": "You are a friendly sales assistant helping customers with product inquiries.",
  "prompt": "Greet the customer warmly and ask how you can help them today.",
  "voice_type": "alloy",
  "temperature": 0.7
}
```

**Response:**
```json
{
  "status": "success",
  "scenario_id": "custom_123_1641234567",
  "message": "Custom scenario created successfully"
}
```

#### Get User Scenarios
**Endpoint:** `GET /custom-scenarios`

**Response:**
```json
[
  {
    "id": 1,
    "scenario_id": "custom_123_1641234567",
    "persona": "You are a friendly sales assistant...",
    "prompt": "Greet the customer warmly...",
    "voice_type": "alloy",
    "temperature": 0.7,
    "created_at": "2024-01-15T10:30:00Z"
  }
]
```

### Welcome Call (Step 4)

#### Make Custom Call
**Endpoint:** `GET /make-custom-call/{phone_number}/{scenario_id}`

**Parameters:**
- `phone_number` - Phone number to call (with or without + prefix)
- `scenario_id` - ID of the custom scenario to use

**Example:** `GET /make-custom-call/+14155551234/custom_123_1641234567`

**Response:**
```json
{
  "status": "success",
  "call_sid": "CA1234567890abcdef",
  "message": "Custom call initiated successfully with scenario: friendly sales assistant",
  "scenario_id": "custom_123_1641234567"
}
```

## Provider Credentials Management

### Get Provider Credentials (Masked)
**Endpoint:** `GET /onboarding/me/providers`

**Response:**
```json
{
  "openai_api_key": "***1234",
  "twilio_account_sid": "***5678",
  "twilio_auth_token": "***9012",
  "twilio_phone_number": "***1234",
  "twilio_vi_sid": "***3456"
}
```

### Update Provider Credentials
**Endpoint:** `PUT /onboarding/me/providers`

**Request Body:**
```json
{
  "openai_api_key": "sk-...",
  "twilio_account_sid": "AC...",
  "twilio_auth_token": "...",
  "twilio_phone_number": "+1234567890",
  "twilio_vi_sid": "VI..."
}
```

**Response:**
```json
{
  "status": "ok"
}
```

## Error Handling

All endpoints follow standard HTTP status codes:

- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `404` - Not Found (resource doesn't exist)
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error

**Error Response Format:**
```json
{
  "detail": "Error message describing what went wrong"
}
```

## Rate Limits

The following rate limits apply:

- `/onboarding/*` endpoints: 10-20 requests/minute
- `/twilio/search-numbers`: Standard rate limits
- `/twilio/provision-number`: Standard rate limits
- `/realtime/custom-scenario`: 10 requests/minute
- `/make-custom-call/*`: 2 requests/minute
- `/google-calendar/auth`: Standard rate limits

## Frontend Implementation Examples

### Complete Onboarding Flow

```javascript
class OnboardingManager {
  async getStatus() {
    const response = await fetch('/onboarding/status', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    return response.json();
  }

  async completeStep(step) {
    const response = await fetch('/onboarding/complete-step', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ step })
    });
    return response.json();
  }

  async setupPhone(areaCode = null) {
    // 1. Search for numbers
    const searchResponse = await fetch('/twilio/search-numbers', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ area_code: areaCode, limit: 5 })
    });
    const { availableNumbers } = await searchResponse.json();

    // 2. Let user select a number
    const selectedNumber = availableNumbers[0]; // or let user choose

    // 3. Provision the number
    const provisionResponse = await fetch('/twilio/provision-number', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ phone_number: selectedNumber.phoneNumber })
    });

    return provisionResponse.json();
  }

  async connectCalendar() {
    const response = await fetch('/google-calendar/auth', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const { authorization_url } = await response.json();
    
    // Redirect user to Google OAuth
    window.location.href = authorization_url;
  }

  async createScenario(persona, prompt, voiceType = 'alloy') {
    const response = await fetch('/realtime/custom-scenario', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        persona,
        prompt,
        voice_type: voiceType,
        temperature: 0.7
      })
    });
    return response.json();
  }

  async makeWelcomeCall(phoneNumber, scenarioId) {
    const response = await fetch(`/make-custom-call/${phoneNumber}/${scenarioId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    return response.json();
  }
}
```

### React Component Example

```jsx
import { useState, useEffect } from 'react';

function OnboardingFlow() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStatus();
  }, []);

  const loadStatus = async () => {
    try {
      const response = await fetch('/onboarding/status', {
        headers: { 'Authorization': `Bearer ${getToken()}` }
      });
      const data = await response.json();
      setStatus(data);
    } catch (error) {
      console.error('Failed to load onboarding status:', error);
    } finally {
      setLoading(false);
    }
  };

  const renderCurrentStep = () => {
    if (!status) return null;

    switch (status.currentStep) {
      case 'phone_setup':
        return <PhoneSetup onComplete={loadStatus} />;
      case 'calendar':
        return <CalendarSetup onComplete={loadStatus} />;
      case 'scenarios':
        return <ScenarioSetup onComplete={loadStatus} />;
      case 'welcome_call':
        return <WelcomeCall onComplete={loadStatus} />;
      case 'complete':
        return <OnboardingComplete />;
      default:
        return <div>Loading...</div>;
    }
  };

  if (loading) return <div>Loading onboarding...</div>;

  return (
    <div className="onboarding-flow">
      <div className="progress-bar">
        <div 
          className="progress-fill" 
          style={{ width: `${status.completionPercentage}%` }}
        />
      </div>
      <h2>Setup Progress: {status.completionPercentage}%</h2>
      {renderCurrentStep()}
    </div>
  );
}
```

## Notes

1. **Sequential Flow**: Steps must be completed in order. Later steps are not available until previous steps are completed.

2. **Auto-completion**: The system automatically detects when steps are completed through other actions (e.g., provisioning a phone number automatically completes the phone_setup step).

3. **Persistence**: Onboarding status is persisted in the database and survives user sessions.

4. **Security**: All endpoints require authentication and include rate limiting for protection.

5. **Error Recovery**: If onboarding initialization fails during registration, it can be manually triggered using `/onboarding/initialize`.

6. **Google Calendar Callback**: The OAuth callback for Google Calendar automatically redirects to your frontend with success/error parameters.

This documentation provides everything your frontend team needs to implement a complete onboarding experience for your speech assistant application.