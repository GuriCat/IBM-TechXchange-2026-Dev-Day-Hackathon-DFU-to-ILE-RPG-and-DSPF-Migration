## Skill: Develop an MCP Server using Quarkus

### Purpose
Enable Bob to develop an MCP Server with Quarkus.

### Overview
Quarkus provides an extension to create MCP Servers.
Both `stdio` and `http/sse` modes are supported but this rule defaults to `http` mode.

### Core Rules
1. Always use the Quarkus MCP server to list the available extensions.
2. Always use the Quarkus MCP server to add the `quarkus-mcp-server-http` extension.
3. Always use the http mode and configure the http port to 8888 using the `quarkus.http.port` property.
4. Configure the application with `quarkus.http.cors.enabled` to true.
5. Use the `@io.quarkiverse.mcp.server.Tool` annotation to make a method an MCP tool and `@io.quarkiverse.mcp.server.ToolArg` to describe the arguments.
6. Understand the MCP endpoints and arguments to provide a valid description.
7. Use `io.quarkiverse.mcp.server.ToolResponse` as return type and `io.quarkiverse.mcp.server.TextContent` to set the result.

### Example Resource

An MCP server communicating via Streamable HTTP transport:

```java

import dev.langchain4j.agent.tool.Tool;
import dev.langchain4j.agent.tool.P;

public class GreetingTools {

    @Tool(description = "Greet a user by name")
    public String greet(@ToolArg(description = "Name of the user") String name) {
    return ToolResponse.success(
    new TextContent("Hello, " + name + "!"));
    }
}
```

### Notes
- Use Quarkus MCP Server to add dependencies.
- Develop the MCP tools (they can be more than one) dependsing on the requirements specified by user.

### Validation Check
After registering the extension, Bob should:
- Verify that the all MCP methods are valid and annotated correctly.
