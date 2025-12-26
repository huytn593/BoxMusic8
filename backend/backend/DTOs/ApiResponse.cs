namespace backend.DTOs;

public class ApiResponse
{
    public string Message { get; set; }
    public bool Success { get; set; }
    public object Data { get; set; }

    public static ApiResponse SuccessResponse(string message, object data = null)
    {
        return new ApiResponse
        {
            Message = message,
            Success = true,
            Data = data
        };
    }

    public static ApiResponse ErrorResponse(string message)
    {
        return new ApiResponse
        {
            Message = message,
            Success = false
        };
    }
} 