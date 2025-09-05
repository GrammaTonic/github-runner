# Release Notes v1.1.1

**Release Date:** September 5, 2025  
**Type:** Security Update  

## 🔒 Security Fixes

### CVE-2023-52576 - MEDIUM Severity

**Fixed vulnerability in linux-libc-dev package**

- **Issue**: CVE-2023-52576 kernel vulnerability affecting memblock allocator
- **Impact**: Potential use-after-free in memblock_isolate_range() 
- **Resolution**: Upgraded base Docker images from Ubuntu 22.04 to Ubuntu 24.04 LTS
- **Package Update**: linux-libc-dev from 5.15.0-153.163 to 6.8.0-79.79

**Risk Assessment**: Low impact in containerized environment, but proactively resolved.

## 📦 Platform Updates

### Base Image Upgrade

- **Standard Runner**: Updated to Ubuntu 24.04 LTS
- **Chrome Runner**: Updated to Ubuntu 24.04 LTS  
- **Benefits**: 
  - Latest security patches
  - Improved hardware support
  - Better performance
  - Extended LTS support until 2029

## 🔧 Technical Changes

### Modified Files
- `docker/Dockerfile`: Ubuntu 22.04 → 24.04
- `docker/Dockerfile.chrome`: Ubuntu 22.04 → 24.04
- Updated version labels to 1.0.1

### Compatibility
- ✅ Backward compatible
- ✅ All existing features preserved
- ✅ No breaking changes
- ✅ Same GitHub Actions runner version (2.328.0)

## 🧪 Testing

- ✅ Docker build validation passed
- ✅ Package installation verified  
- ✅ Security scan confirms CVE resolved
- ✅ Hadolint Docker linting passed

## 📚 Documentation

- Added security fix documentation: `docs/security/CVE-2023-52576-fix.md`
- Includes detailed impact assessment and remediation steps

## 🛡️ Security Recommendations

1. **Immediate**: Rebuild and redeploy runner images
2. **Ongoing**: Continue automated security scanning
3. **Future**: Plan quarterly base image updates

---

**Previous Version:** v1.1.0  
**Breaking Changes:** None  
**Migration Required:** No