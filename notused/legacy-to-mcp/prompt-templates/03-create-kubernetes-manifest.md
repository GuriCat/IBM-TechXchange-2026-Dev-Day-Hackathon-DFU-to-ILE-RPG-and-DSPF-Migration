
# Creates the Kubernetes manifest

**Mode:** Quarkus Developer

**Context:**

Create a Kubernetes manifest that deploys the legacy application together with the MCP Server as a sidecar container.

**Prompt:**

```
The Kubernetes manifest to deploy the petclinic application is located in the src/main/kubernetes folder. Modify the manifest to add the PetClinic MCP server as a sidecar container.
```

**Result:**

* Bob creates a Kubernetes Deployment file, with the Service, Route (in case of OpenShift), so it deploys both the legacy app and the MCP Server together in the same Pod.

---


