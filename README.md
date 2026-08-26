# HelloApi

A simple ASP.NET Core (.NET 9) minimal Web API demo.

## Endpoints

| Method | Route            | Description                          |
|--------|------------------|--------------------------------------|
| GET    | `/hello`         | Returns `{ "message": "Hello, World!" }` |
| GET    | `/hello/{name}`  | Returns a personalized greeting      |

## Run

```bash
cd HelloApi
dotnet run
```

Then open the OpenAPI document at `/openapi/v1.json` (Development) or call an endpoint:

```bash
curl http://localhost:5271/hello
curl http://localhost:5271/hello/Sanjay
```
