using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;

namespace AuthorizationAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class AuthController : ControllerBase
{
    private readonly ILogger<AuthController> _logger;
    private readonly IMemoryCache _cache;

    public AuthController(ILogger<AuthController> logger, IMemoryCache cache)
    {
        _logger = logger;
        _cache = cache;
    }

    [HttpGet(Name = "GetApiKeys")]
    public IActionResult GetApiKey()
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            return Ok(apiKeys);
        }

        return NotFound();
    }

    [HttpPost(Name = "AddApiKey")]
    public IActionResult AddApiKey([FromBody] string apiKey)
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            apiKeys.Add(apiKey);
            _cache.Set("ApiKeys", apiKeys);
            _logger.LogInformation("Added ApiKey: {ApiKey}", apiKey);
            return Ok();
        }

        var newApiKeys = new List<string> { apiKey };
        _cache.Set("ApiKeys", newApiKeys);
        _logger.LogInformation("Added ApiKey: {ApiKey}", apiKey);
        return Ok();
    }

    [HttpDelete(Name = "DeleteApiKey")]
    public IActionResult DeleteApiKey([FromBody] string apiKey)
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            apiKeys.Remove(apiKey);
            _cache.Set("ApiKeys", apiKeys);
            _logger.LogInformation("Deleted ApiKey: {ApiKey}", apiKey);
            return Ok();
        }

        _logger.LogWarning("ApiKey: {ApiKey} not found", apiKey);
        return NotFound();
    }

    [HttpGet("Validate", Name = "ValidateApiKey")]
    public IActionResult ValidateApiKey([FromQuery] string apiKey)
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            if (apiKeys.Contains(apiKey))
            {
                return Ok();
            }
        }

        return NotFound();
    }

    [HttpGet("ValidateHeader", Name = "ValidateApiKeyHeader")]
    public IActionResult ValidateApiKeyHeader([FromHeader(Name = "x-api-key")] string apiKey)
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            if (apiKeys.Contains(apiKey))
            {
                return Ok();
            }
        }

        return NotFound();
    }

    [HttpPost("ValidateBody", Name = "ValidateApiKeyBody")]
    public IActionResult ValidateApiKeyBody([FromBody] string apiKey)
    {
        if (_cache.TryGetValue("ApiKeys", out List<string>? apiKeys))
        {
            if (apiKeys.Contains(apiKey))
            {
                return Ok();
            }
        }

        return NotFound();
    }
}