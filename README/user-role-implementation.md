# Two-Layered Verification Process Implementation

## Overview
This document describes the implementation of a two-layered verification process with user roles (Seller/User) in the Flutter e-commerce app.

## User Roles

### 1. User (Regular Customer)
- **Capabilities:**
  - Browse and purchase products
  - View favorites and order history
  - Edit personal profile information
  - Cannot edit product information or images
  - Limited to shopping features only

### 2. Seller
- **Capabilities:**
  - All user capabilities
  - Create and manage products
  - Edit product information and images
  - Access to stock management
  - View all orders and manage inventory

## Implementation Details

### 1. User Model Updates (`lib/models/app_user.dart`)
- Added `userRole` field to store user role ('seller' or 'user')
- Added helper methods `isSeller` and `isUser`
- Default role is 'user' if not specified

### 2. User Role Provider (`lib/providers/user_role_provider.dart`)
- `userRoleProvider`: Fetches current user's role from Firestore
- `isSellerProvider`: Boolean provider to check if user is a seller
- `isUserProvider`: Boolean provider to check if user is a regular user

### 3. Registration Screen Updates (`lib/screens/auth/register_screen.dart`)
- Added required dropdown for user role selection
- Role selection is mandatory during registration
- Shows role information and capabilities
- Saves selected role to Firestore user document

### 4. Profile Tab Updates (`lib/screens/tabs/profile_tab.dart`)
- Shows user role badge (Seller/User)
- Conditional rendering of seller-only buttons:
  - "Create New Item" button (sellers only)
  - "Stock Management" button (sellers only)
- Regular users only see: Favorites, My Orders, and Logout

### 5. Product Screen Updates (`lib/screens/product/item_screen.dart`)
- Edit button only visible to sellers
- Regular users cannot edit product information or images
- Maintains browsing and purchasing capabilities for all users

## Database Schema

### Users Collection
```json
{
  "uid": "user_id",
  "name": "User Name",
  "email": "user@example.com",
  "address": "User Address",
  "phone": "Phone Number",
  "userRole": "seller" | "user",
  "createdAt": "timestamp",
  "purchaseHistory": [],
  "totalPurchases": 0,
  "lastPurchaseDate": null
}
```

## Security Considerations

1. **Client-side Role Validation**: While we implement role-based UI restrictions, server-side validation should also be implemented for production use.

2. **Firestore Security Rules**: Consider implementing Firestore security rules to restrict access based on user roles.

3. **Role Persistence**: User roles are stored in Firestore and persist across sessions.

## Usage Examples

### Checking User Role in Widgets
```dart
// Using the provider
final isSeller = ref.watch(isSellerProvider);
final isUser = ref.watch(isUserProvider);

// Conditional rendering
if (isSeller) {
  // Show seller-only features
}
```

### Role-based Navigation
```dart
// Only show seller routes to sellers
if (ref.read(isSellerProvider)) {
  AppRoutes.navigateToCreateItem(context);
}
```

## Future Enhancements

1. **Admin Role**: Add an admin role with additional privileges
2. **Role Management**: Allow admins to change user roles
3. **Role-based Analytics**: Track user behavior based on roles
4. **Advanced Permissions**: Granular permissions for different features

## Testing

To test the implementation:

1. **Register as a User**: Create account with "User" role
   - Verify only basic features are available
   - Confirm edit buttons are hidden

2. **Register as a Seller**: Create account with "Seller" role
   - Verify all features are available
   - Confirm edit buttons are visible

3. **Role Switching**: Test role-based UI changes
   - Verify correct buttons appear/disappear
   - Confirm navigation restrictions work

## Files Modified

- `lib/models/app_user.dart` - Added userRole field
- `lib/providers/user_role_provider.dart` - New provider for role management
- `lib/screens/auth/register_screen.dart` - Added role selection dropdown
- `lib/screens/tabs/profile_tab.dart` - Conditional UI based on role
- `lib/screens/product/item_screen.dart` - Role-based edit button visibility
