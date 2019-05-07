# Distributed-Bulletin-Board

Created a distributed bulletin board system that allows users to subscribe to specific topic, post
new information about a topic, or view the content posted to a topic. Newly posted information is forwarded to all currently subscribed users.

The 3 operations that a user can do is subsribue, unsubsribe, or post to a topic. The topic manager is responsible for handling the subscription of users and implementing the broadcast of newly posted information to the current subscribers. To ensure fault-tolerance, a topic manager is replicated on all available user nodes.
