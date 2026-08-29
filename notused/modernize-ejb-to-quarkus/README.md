# Modernization Journey: [Migrating EJB application to Quarkus]

This demo shows how to use Bob to transform an EJB appluication into a Quarkus application.
Of course, you can use the same approach to convert an EJB application to REST API, it is not mandatory to convert to Quarkus.
But we choose this way as Quarkus doesn't support EJBs.


**Date added:** [04/10/2026]  
**Duration:** 10 min 
**Mode(s) Used:** Advanced mode

## Initial Goal

Convert an EJB deployed into OpenLiberty to a Quarkus application.

---

## Step-by-Step Process

### Step 1: Open IBM Bob 

Open IBM Bob and import the [input-documents/modernization-ejb-stateless](input-documents/modernization-ejb-stateless) project.

**Outcome:**

IBM Bob IDE has the empty Quarkus project.


### Step 2: Time for Prompting

At this point, we can start prompting Bob and check the [prompt-templates](prompt-templates/) folder for the prompts.

---

## Final Outcome

**What was achieved:**
- Quarkus application with the same logic of the EJB but as a CDI bean and Rest API
