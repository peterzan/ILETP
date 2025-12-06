<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2025 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Specification 2: The Trust & Consensus Protocol

## Specification Concepts

### Concept 1:
A method for generating a trust score for an AI system's output based on the consensus of multiple independent agents, including:* Agent agreement and dissent on the output.* Weighting of trust based on the agent's historical performance and confidence level.* Auditability and traceability of the reasoning behind the score.

### Concept 2:
The method of Concept 1, wherein the trust score is used as a safety metric, ensuring that high-stakes decisions (e.g., robotic actions, autonomous vehicle navigation) are only made when the trust score reaches a defined threshold.

## Specification
The Trust and Consensus Protocol: A System for Verifying Collective Information

### Description
The Trust and Security Core is an essential module designed to validate the reliability, accuracy, and safety of the information processed by the system. Instead of relying on a single agent's output, this module evaluates the collective responses from all contributing agents. It calculates a dynamic trust score based on a predefined methodology that considers factors such as agent-reported confidence, consistency between multiple agent responses, adherence to a security protocol (e.g., a "disallowed terms" list), and the source of the data. This trust score is a crucial gatekeeper, determining whether information can be presented to the user or if further action, such as a recovery protocol, is required.

### Example Use Case
A user asks for information on a highly controversial historical event. Three different agents are assigned the task.* Agent A provides a response with a high confidence score, but its content is flagged by the security protocol for using potentially biased language.* Agent B provides a response with a low confidence score and references an unreliable source.* Agent C provides a response with a moderate confidence score and references a well-known academic source.The Trust and Security Core evaluates these three responses, notes the conflicts, and calculates a collective trust score below the acceptable threshold. As a result, the information is not presented to the user, and the Session Recovery Protocol is triggered.

## Pseudocode
Non-normative conceptual illustration
Mirrors the logical flow from Specification 2: The Trust & Consensus Protocol
Implementation-defined aspects are marked with comments

### Overview
The Trust & Consensus Protocol evaluates outputs from multiple AI agents to generate a dynamic trust score. This score reflects the collective reliability of information based on agent agreement, historical performance, confidence levels, policy compliance, and source quality. The trust score serves as a safety gate for high-stakes decisions.

### Core Logic

```
FUNCTION calculateTrustScore(agentOutputs, query):
  
  // Phase 1: Collect Agent Metrics
  FOR EACH output IN agentOutputs:
    confidence = output.getConfidenceLevel()
    historicalPerformance = getAgentHistory(output.agentID)
    sourceQuality = evaluateSourceReliability(output.sources)
    policyCompliance = checkSecurityPolicy(output.content)
    
    STORE metrics for output
  END FOR
  
  // Phase 2: Consensus Analysis
  consensusLevel = measureAgreement(agentOutputs)
    WHERE consensusLevel measures:
      - semantic similarity between outputs
      - factual alignment
      - conclusion consistency
  
  dissent = identifyDissent(agentOutputs)
  
  // Phase 3: Weighted Trust Calculation
  trustScore = 0
  
  FOR EACH output IN agentOutputs:
    weight = calculateWeight(
      historicalPerformance,
      confidence,
      sourceQuality,
      policyCompliance
    )
    
    contributionScore = weight × consensusAlignment(output)
    trustScore += contributionScore
  END FOR
  
  trustScore = normalize(trustScore, agentOutputs.count)
  
  // Phase 4: Threshold Evaluation
  IF trustScore >= TRUST_THRESHOLD:
    decision = APPROVE
  ELSE:
    decision = REJECT
    triggerRecoveryProtocol(query, agentOutputs, trustScore)
  END IF
  
  // Phase 5: Audit Trail
  auditLog = CREATE log containing:
    - individual agent scores and weights
    - consensus/dissent analysis
    - policy compliance results
    - final trust score and reasoning
    - threshold comparison
    - decision rationale
  
  STORE auditLog
  
  RETURN trustScore, decision, auditLog

END FUNCTION
```

### Supporting Functions

```
FUNCTION measureAgreement(outputs):
  // Analyzes semantic and factual alignment across outputs
  RETURN consensus percentage

FUNCTION calculateWeight(history, confidence, quality, compliance):
  weight = (history × factor1) + 
           (confidence × factor2) + 
           (quality × factor3) + 
           (compliance × factor4)
  RETURN normalized weight

FUNCTION checkSecurityPolicy(content):
  // Scans for disallowed terms, bias indicators, harmful content
  RETURN compliance score

FUNCTION triggerRecoveryProtocol(query, outputs, score):
  // Initiates recovery process when trust threshold not met
  EXECUTE recovery procedures




