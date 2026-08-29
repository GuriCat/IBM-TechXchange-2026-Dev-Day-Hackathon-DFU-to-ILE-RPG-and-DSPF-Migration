

# Creates a Rest Client to connect to an external API

**Mode:** Quarkus Developer

**Context:**

First, create a REST client that connects to the Spring Petclinic app.
For this example, we'll only implement the read operations to avoid exposing the entire application to the MCP server.

**Prompt:**

```
Can you generate a Quarkus REST client that connects to a REST API following the spec at https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/refs/heads/master/src/main/resources/openapi.yml? Only implement the reading operations of pets.
```

**Result:**

* Bob creates a MicroProfile Rest Client to connect to the legacy app.

**Follow-up Actions:**

- Creating the MCP Server

---
