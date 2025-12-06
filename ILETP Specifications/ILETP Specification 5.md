<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2025 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Specification 5: Asynchronous Task & Notification
## Specification  Concepts
### Specification Concept 1: 
A method for managing long-running tasks across multiple AI agents, including:* Task delegation to an agent or set of agents.* Proactive notifications to inform the user of task progress, completion, or blockers, even if the user is not actively interacting with the system.
* ### Specification Concept 2: 
The method of Invention Concept 1, wherein notifications can trigger specific actions, such as reassigning tasks, adding context, or approving the next steps in the process.
## SpecificationAsynchronous Task & Notification: A Method for Long-Running Task Management
### DescriptionThis system is designed to handle tasks that require a significant amount of time or do not require an immediate response from the user. It functions by decoupling the task initiation from the user's active session. An agent or group of agents is delegated a long-running task, and the system provides a persistent, trackable ID for that task. The user is then freed from the waiting state and is notified of progress or completion through proactive, push-based notifications. This system ensures that the platform remains responsive and can handle complex, multi-stage tasks without tying up the user's interface. It also includes a mechanism for the user to provide new input or trigger a specific action based on a notification, creating a seamless and efficient workflow.
### Example Use CaseA user provides the query: "Analyze all the recent market data for the last quarter and provide a detailed report on trends." The system processes this request and performs the following actions:* The Orchestration Engine identifies this as a long-running task.* It delegates the task to a Financial Analyst Agent.* The user is immediately notified that the report has been initiated and will be provided asynchronously.* While the agent is working, the user closes the chat window and continues with other work.* Two hours later, the Financial Analyst Agent completes the report.* The system sends a push notification to the user's device that the report is complete and available.## Pseudocode
Non-normative conceptual illustration
Mirrors the logical flow from Specification 5: Asynchronous Task & Notification
Implementation-defined aspects are marked with comments

### Overview
The Asynchronous Task & Notification System manages long-running operations by decoupling task execution from active user sessions. It provides persistent task tracking, proactive progress notifications, and interactive callbacks that allow users to influence execution without maintaining continuous connection.

### Core Logic

```
FUNCTION initiateLongRunningTask(userID, taskRequest):
  
  // Phase 1: Task Registration
  taskID = generateUniqueTaskID()
  task = CREATE task object:
    - taskID
    - userID
    - request details
    - status = PENDING
    - createdTimestamp
    - estimatedDuration
    - priority
  
  SAVE task TO persistentStorage
  
  // Phase 2: Agent Delegation
  suitableAgents = selectAgentsForTask(taskRequest)
  delegateTask(taskID, suitableAgents)
  
  // Phase 3: Immediate User Feedback
  acknowledgment = CREATE notification:
    - "Task initiated: [task summary]"
    - taskID for tracking
    - estimatedCompletion time
    - link to task status dashboard
  
  sendNotification(userID, acknowledgment)
  
  // Phase 4: Async Execution
  executeTaskAsync(taskID, suitableAgents)
  
  RETURN taskID

END FUNCTION


FUNCTION executeTaskAsync(taskID, agents):
  
  // Runs in background, non-blocking
  task = RETRIEVE task FROM persistentStorage WHERE taskID matches
  
  TRY:
    // Phase 1: Execution with Progress Tracking
    FOR EACH stage IN task.stages:
      
      result = agents.executeStage(stage)
      
      // Update task status
      task.status = IN_PROGRESS
      task.currentStage = stage.name
      task.completionPercentage = calculateProgress(task)
      SAVE task TO persistentStorage
      
      // Proactive progress notifications
      IF shouldNotifyProgress(task, stage):
        progressNotification = CREATE notification:
          - "Task [taskID] progress: [stage.name] complete"
          - completionPercentage
          - estimatedTimeRemaining
        sendNotification(task.userID, progressNotification)
      END IF
      
      // Check for blockers
      IF stage.requiresUserInput OR stage.hasBlocker:
        blockerNotification = CREATE actionable notification:
          - "Task [taskID] requires your input"
          - blocker description
          - available actions: [APPROVE, PROVIDE_CONTEXT, CANCEL]
          - callback mechanism
        
        sendNotification(task.userID, blockerNotification)
        
        // Pause execution until user responds
        WAIT FOR userResponse
        handleUserAction(taskID, userResponse)
      END IF
      
    END FOR
    
    // Phase 2: Task Completion
    task.status = COMPLETED
    task.completedTimestamp = currentTime
    task.result = finalResult
    SAVE task TO persistentStorage
    
    completionNotification = CREATE notification:
      - "Task [taskID] completed successfully"
      - result summary
      - link to full results
      - suggested follow-up actions
    
    sendNotification(task.userID, completionNotification)
    
  CATCH error:
    // Phase 3: Error Handling
    task.status = FAILED
    task.error = error details
    SAVE task TO persistentStorage
    
    errorNotification = CREATE actionable notification:
      - "Task [taskID] encountered an error"
      - error description
      - available actions: [RETRY, MODIFY, CANCEL]
    
    sendNotification(task.userID, errorNotification)
  
  END TRY

END FUNCTION


FUNCTION handleUserAction(taskID, userResponse):
  
  task = RETRIEVE task FROM persistentStorage WHERE taskID matches
  
  SWITCH userResponse.action:
    
    CASE APPROVE:
      // Resume execution with approval
      task.approvals.add(userResponse.stage)
      resumeTask(taskID)
    
    CASE PROVIDE_CONTEXT:
      // Add user-provided context
      task.additionalContext = userResponse.context
      resumeTask(taskID)
    
    CASE REASSIGN:
      // Delegate to different agents
      newAgents = selectAgentsForTask(userResponse.requirements)
      delegateTask(taskID, newAgents)
    
    CASE CANCEL:
      // Terminate task
      task.status = CANCELLED
      cleanupResources(taskID)
    
    CASE MODIFY:
      // Update task parameters
      updateTask(taskID, userResponse.modifications)
      resumeTask(taskID)
  
  END SWITCH
  
  SAVE task TO persistentStorage

END FUNCTION
```

### Supporting Functions

```
FUNCTION sendNotification(userID, notification):
  // Push-based delivery across channels
  channels = getUserNotificationChannels(userID)
  
  FOR EACH channel IN channels:
    IF channel = EMAIL:
      sendEmail(userID, notification)
    ELSE IF channel = PUSH:
      sendPushNotification(userID, notification)
    ELSE IF channel = SMS:
      sendSMS(userID, notification)
    ELSE IF channel = IN_APP:
      queueInAppNotification(userID, notification)
    END IF
  END FOR

FUNCTION shouldNotifyProgress(task, stage):
  // Determines if progress update warrants notification
  // Based on: time elapsed, milestone significance, user preferences
  RETURN boolean

FUNCTION getTaskStatus(taskID):
  // User-initiated status check
  task = RETRIEVE task FROM persistentStorage WHERE taskID matches
  RETURN task.status, task.progress, task.currentStage




