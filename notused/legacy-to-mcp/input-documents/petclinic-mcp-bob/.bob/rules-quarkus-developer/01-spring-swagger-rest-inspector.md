
## Skill: Read OpenAPI file and extract certain endpoints

### Purpose
Enable Bob to extract certain endpoints from OpenAPI files.

### Overview
OpenAPI files are used to describe REST endpoints.
Extract endpoints information described by the user from the OpenAPI file.

### Core Rules
1. Read the OpenAPI file and filter the endpoints by the expression provided in prompt.
2. Get the information and keep it in memory as you will need to generate some classes.
3. Usually the OpenAPI file is named `openapi.yml`.

### Notes
- Don't store all the endpoints, only the ones matching the information provided by user in prompt. 
- User might use the _read operations_ to refer to `GET` methods.