#!/usr/bin/env python3

import sys
from openclaw import OpenClaw


def main():
    print("OpenClaw Health Check\n")

    try:
        openclaw = OpenClaw()

        status = openclaw.health_check_all()

        print("System Status:")
        all_healthy = True
        for component, is_healthy in status.items():
            symbol = "OK" if is_healthy else "FAIL"
            print(f"  [{symbol}] {component}: {'healthy' if is_healthy else 'unavailable'}")
            if not is_healthy:
                all_healthy = False

        print(f"\nPending Approvals: {len(openclaw.pending_approvals)}")
        print(f"Local Agents: {len(openclaw.local_agents)}")
        print(f"Cloud Agents: {len(openclaw.cloud_agents)}")

        if all_healthy:
            print("\nAll systems operational")
            return 0
        else:
            print("\nSome components unhealthy")
            return 1

    except Exception as e:
        print(f"Health check failed: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
