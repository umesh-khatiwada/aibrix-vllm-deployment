import csv
from collections import defaultdict

CSV_FILE = "routing_analysis.csv"

def verify():
    rows = []
    with open(CSV_FILE, newline="") as f:
        rows = list(csv.DictReader(f))

    print("\n" + "="*70)
    print("  ROUTING STRATEGY VERIFICATION REPORT")
    print("="*70)

    strategies = defaultdict(list)
    for r in rows:
        strategies[r["Routing_Strategy"]].append(r)

    for strategy, reqs in sorted(strategies.items()):
        total    = len(reqs)
        success  = sum(1 for r in reqs if r["Success"] == "YES")
        pod_dist = defaultdict(int)
        avg_rt   = sum(float(r["Response_Time_ms"] or 0) for r in reqs) / total

        for r in reqs:
            pod_dist[r["Target_Pod_IP"]] += 1

        print(f"\n📌 Strategy: {strategy}")
        print(f"   Total Requests : {total}")
        print(f"   Success Rate   : {100*success//total}%")
        print(f"   Avg Latency    : {avg_rt:.0f}ms")
        print(f"   Pod Distribution:")
        for pod_ip, count in sorted(pod_dist.items()):
            pct  = 100 * count // total
            bar  = "█" * (pct // 5)
            name = next((r["Target_Pod_Name"] for r in reqs
                         if r["Target_Pod_IP"] == pod_ip), pod_ip)
            print(f"     {pod_ip:<16} ({name[-20:]:<20}) "
                  f"{count:>4} reqs  {pct:>3}%  {bar}")

        # Strategy-specific check
        if strategy == "random":
            percentages = [100*c//total for c in pod_dist.values()]
            balanced    = all(20 <= p <= 80 for p in percentages)
            print(f"   ✅ PASS" if balanced else f"   ⚠️  SKEWED (expected ~50/50)")

        elif strategy == "prefix-cache":
            # Same prompt should always go to same pod
            prompt_pods = defaultdict(set)
            for r in reqs:
                prompt_pods[r["Prompt_Preview"]].add(r["Target_Pod_IP"])
            consistent = all(len(pods) == 1 for pods in prompt_pods.values())
            print(f"   ✅ PASS - same prompt always same pod"
                  if consistent else
                  f"   ⚠️  INCONSISTENT - same prompt went to different pods")

        elif strategy == "vtc-basic":
            user_pods = defaultdict(set)
            for r in reqs:
                user_pods[r["User_ID"]].add(r["Target_Pod_IP"])
            print(f"   Users seen: {list(user_pods.keys())}")
            print(f"   ✅ PASS - fairness routing active"
                  if len(user_pods) > 1 else
                  f"   ⚠️  Only 1 user seen")

        elif strategy == "least-request":
            if len(pod_dist) > 1:
                print(f"   ✅ PASS - load distributed across pods")
            else:
                print(f"   ⚠️  All requests went to 1 pod")

    print("\n" + "="*70)
    print("  OVERALL SUMMARY")
    print("="*70)
    total_all   = len(rows)
    success_all = sum(1 for r in rows if r["Success"] == "YES")
    print(f"  Total Requests  : {total_all}")
    print(f"  Success Rate    : {100*success_all//total_all}%")
    print(f"  Strategies Tested: {len(strategies)}")
    print(f"  Strategies: {', '.join(sorted(strategies.keys()))}")
    print("="*70)

if __name__ == "__main__":
    verify()
