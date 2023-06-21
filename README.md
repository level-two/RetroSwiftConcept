# RetroSwift

This project demonstrates the way of API contract definition in the Retrofit-like fashion on Swift.

It gives us possibility to define API in this way:

```swift
final class SchedulesApi: ApiDomain {
    @Get("/api/v1/schedule")
    var getSchedules: (GetSchedulesRequest) async throws -> GetSchedulesResponse

    @Post("/api/v1/schedule")
    var createSchedule: (CreateScheduleRequest) async throws -> CreateScheduleResponse

    @Delete("/api/v1/schedule/{schedule_id}")
    var deleteSchedule: (DeleteScheduleRequest) async throws -> DeleteScheduleResponse
}
```

Additionally to these definitions *Request types provide more details on contract with the endpoints, namely on particular data fields and their matching to the HTTP params - query, header, path, body:

```swift
struct GetSchedulesRequest {
    @Query var page: Int
    @Query("limit") var schedulesPerPage: Int = 0
    @Header("X-Account-Id") var accountId: String = ""
}

struct CreateScheduleRequest {
    @Header("X-Account-Id") var accountId: String = ""
    @Body var scheduleBody: Schedule
}

struct DeleteScheduleRequest {
    @Path("schedule_id") var ScheduleId: String = ""
    @Header("X-Account-Id") var accountId: String = ""
}
```

Usage is quite simple:

```swift
let api = SchedulesApi()
let request = GetSchedulesRequest(page: 1, schedulesPerPage: 30, accountId: "acc_id")
let response = try await api.getSchedules(request)
```

Additionally responses can be mocked in a straightforward and self-describing way:

```swift
api.getSchedules = { _ in
    GetSchedulesResponse(....)
}

api.deleteSchedule = { _ in
    throw URLError(.userAuthenticationRequired)
}
```
