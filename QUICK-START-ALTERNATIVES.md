# Quick Start: Choosing a Kibana Alternative

**Need to visualize Apache NiFi metrics but don't want to use Kibana?** This guide helps you choose the right alternative in 5 minutes.

## 🤔 Which Alternative Should I Choose?

### Answer These Questions:

1. **What's your primary use case?**
   - Real-time operational monitoring → **Grafana**
   - Business intelligence and analytics → **Apache Superset**
   - Metrics-focused with alerting → **Prometheus + Grafana**
   - Simple dashboards for business users → **Metabase**
   - SQL-based analysis and reports → **Redash**

2. **What's your team's technical expertise?**
   - DevOps/SRE team → **Grafana** or **Prometheus + Grafana**
   - Data analysts → **Redash** or **Apache Superset**
   - Business users → **Metabase**
   - Developers → **Custom Web App**

3. **What's your budget?**
   - Free only → **Grafana OSS**, **Superset**, **Prometheus**, **Metabase OSS**
   - Managed service OK → **Grafana Cloud**, **Metabase Cloud**

4. **What other tools are you using?**
   - Already using Grafana → **Grafana** (add Elasticsearch datasource)
   - Already using Prometheus → **Prometheus + Grafana**
   - Using multiple monitoring tools → **Grafana** (multi-source support)

## 🚀 Top 3 Recommendations

### #1: Grafana (Most Popular)
**Best for**: 90% of use cases

✅ Quick setup (30 minutes)  
✅ Native Elasticsearch support  
✅ Excellent alerting  
✅ Large community  

**Get Started**:
```bash
docker run -d -p 3000:3000 grafana/grafana
# Access: http://localhost:3000 (admin/admin)
# Add Elasticsearch datasource
# Import dashboard templates
```

See [ALTERNATIVES.md - Grafana Section](ALTERNATIVES.md#1--grafana-recommended-alternative) for full setup.

---

### #2: Apache Superset (Best for BI)
**Best for**: SQL users, business intelligence, cross-database analytics

✅ Powerful SQL editor  
✅ Semantic layer  
✅ Advanced analytics  

**Get Started**:
```bash
docker run -d -p 8088:8088 apache/superset
# Follow initialization steps
# Connect to Elasticsearch
```

See [ALTERNATIVES.md - Superset Section](ALTERNATIVES.md#2--apache-superset) for full setup.

---

### #3: Metabase (Easiest for Non-Technical Users)
**Best for**: Business stakeholders, simple dashboards

✅ 5-minute setup  
✅ No SQL required  
✅ Beautiful UI  

**Get Started**:
```bash
docker run -d -p 3001:3000 metabase/metabase
# Access: http://localhost:3001
# Add Elasticsearch via JDBC
```

See [ALTERNATIVES.md - Metabase Section](ALTERNATIVES.md#4--metabase) for full setup.

---

## 📊 Feature Comparison at a Glance

| Feature | Grafana | Superset | Prometheus+Grafana | Metabase |
|---------|---------|----------|-------------------|----------|
| Real-time monitoring | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Alerting | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| SQL analytics | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Ease of use | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Multi-source | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Setup time | 30 min | 45 min | 60 min | 10 min |

---

## ⚡ Next Steps

1. **Choose your alternative** from the table above
2. **Read the detailed guide** in [ALTERNATIVES.md](ALTERNATIVES.md)
3. **Deploy** using Docker/native installation
4. **Migrate** your dashboards from Kibana (migration guides included)
5. **Configure** alerting and notifications
6. **Test** with your NiFi data

## 🆘 Still Unsure?

- **Question**: "I just want something that works quickly"  
  **Answer**: Use **Metabase** - 5-minute setup, no configuration needed

- **Question**: "I need advanced alerting and multi-source monitoring"  
  **Answer**: Use **Grafana** - industry standard with best alerting

- **Question**: "My team loves SQL and BI tools"  
  **Answer**: Use **Apache Superset** - powerful SQL editor and semantic layer

- **Question**: "I'm running on Kubernetes"  
  **Answer**: Use **Prometheus + Grafana** - native K8s integration

## 📚 Full Documentation

For complete setup instructions, code examples, dashboard templates, and migration guides, see:

**[ALTERNATIVES.md - Complete Guide](ALTERNATIVES.md)**

---

**Questions?** Open an issue at https://github.com/talentGitHub/ApacheNiFi/issues
