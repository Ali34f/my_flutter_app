const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Function triggered when order status changes
exports.sendOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    try {
      // Check if status actually changed
      if (beforeData.status === afterData.status) {
        console.log('Status did not change, skipping notification');
        return null;
      }
      
      const orderId = context.params.orderId;
      const newStatus = afterData.status;
      const orderNumber = afterData.orderId || orderId.substring(orderId.length - 6);
      const deviceToken = afterData.deviceToken;
      
      console.log('Status changed for order ' + orderId + ': ' + beforeData.status + ' -> ' + newStatus);
      
      if (!deviceToken) {
        console.log('No device token found for order:', orderId);
        return null;
      }
      
      const title = getNotificationTitle(newStatus);
      const body = getNotificationBody(newStatus, orderNumber);
      
      // Create the notification message
      const message = {
        token: deviceToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          orderId: orderId,
          status: newStatus,
          type: 'order_update',
          orderNumber: orderNumber,
        },
        android: {
          notification: {
            icon: 'ic_launcher',
            color: '#DC143C',
            sound: 'default',
            channelId: 'order_updates',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Notification sent successfully:', response);
      
      // Store notification record for history
      await admin.firestore().collection('notifications').add({
        orderId: orderId,
        status: newStatus,
        title: title,
        body: body,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        sent: true,
        type: 'order_update',
        deviceToken: deviceToken.substring(0, 20) + '...',
        messageId: response,
      });
      
      console.log('Notification record created');
      return response;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      
      // Store failed notification
      const orderIdParam = context.params.orderId;
      const statusValue = afterData && afterData.status ? afterData.status : 'unknown';
      
      await admin.firestore().collection('notifications').add({
        orderId: orderIdParam,
        status: statusValue,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
        error: error.message,
        type: 'order_update_failed',
      });
      
      return null;
    }
  });

function getNotificationTitle(status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Order Received!';
    case 'confirmed':
      return 'Order Confirmed!';
    case 'preparing':
      return 'Food Being Prepared!';
    case 'ready':
      return 'Order Ready for Collection!';
    case 'collected':
      return 'Order Collected!';
    default:
      return 'Order Update';
  }
}

function getNotificationBody(status, orderNumber) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'We have received order #' + orderNumber + ' and will start preparing it soon!';
    case 'confirmed':
      return 'Order #' + orderNumber + ' confirmed. Estimated time: 25-35 minutes.';
    case 'preparing':
      return 'Our chefs are now preparing your delicious order #' + orderNumber + '!';
    case 'ready':
      return 'Order #' + orderNumber + ' is ready! Please come and collect it.';
    case 'collected':
      return 'Thank you for collecting order #' + orderNumber + '! Enjoy your meal!';
    default:
      return 'Order #' + orderNumber + ' status updated to: ' + status;
  }
}
