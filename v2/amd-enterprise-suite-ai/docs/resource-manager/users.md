# Users & Access

The Resource Manager handles all user management — adding users, assigning roles, and configuring authentication methods.

---

## User Roles

| Role | Access Level |
|---|---|
| **Platform Admin** | Full access to all projects, clusters, and settings |
| **Project Admin** | Full access within their assigned projects |
| **Developer** | Can create and run workloads within assigned projects |
| **Viewer** | Read-only access to their project |

---

## Adding Users

### Via Email Invitation (SMTP)

1. Configure SMTP (see [SMTP Setup](#smtp-configuration) below)
2. Go to **Resource Manager → Users → Add User**
3. Enter the user's email address
4. Select their platform role
5. Click **Invite** — they'll receive an email with a setup link

### Manually

1. Go to **Resource Manager → Users → Add User**
2. Enter name, email, and a temporary password
3. The user logs in and changes their password on first login

---

## Single Sign-On (SSO)

For teams using a corporate identity provider (Okta, Azure AD, Google, etc.):

1. Go to **Resource Manager → Users → Set Up → Enable SSO**
2. Configure your identity provider details
3. Users sign in with their corporate credentials — no separate passwords needed

 [SSO Setup Guide](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/users/set-up/sso.html)

---

## SMTP Configuration

SMTP is needed to send email invitations and password reset emails.

1. Go to **Resource Manager → Users → Set Up → Configure SMTP**
2. Enter your SMTP server details:
    - Host, port
    - Username and password
    - Sender email address
3. Send a test email to verify

 [SMTP Configuration Guide](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/users/set-up/smtp-configuration.html)

---

## Managing Existing Users

Go to **Resource Manager → Users** to:

- View all users and their roles
- Edit a user's role
- Deactivate or delete users
- View user activity

---

## Official Reference

 [Users Docs](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/users/overview.html)
